import Foundation
import SocketIO
import Combine
import UIKit

/// Thread-safe message subscription token
final class MessageSubscription {
    fileprivate let id: UUID
    fileprivate weak var service: SocketService?
    
    fileprivate init(id: UUID, service: SocketService) {
        self.id = id
        self.service = service
    }
    
    deinit {
        cancel()
    }
    
    func cancel() {
        service?.unsubscribe(id: id)
    }
}

/// Pub/Sub message handler type
typealias MessageHandler = (String, [String: Any]) -> Void

/// Thread-safe Socket.IO service with proper message routing
class SocketService: ObservableObject {
    // MARK: - Configuration
    #if DEBUG
    private static let defaultServerURL = "https://rackrush-server-production.up.railway.app"
    #else
    private static let defaultServerURL = "https://rackrush-server-production.up.railway.app"
    #endif
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    
    private let serverURL: String
    private var deviceId: String
    
    // MARK: - Pub/Sub Message Router
    private var subscribers: [UUID: MessageHandler] = [:]
    private var typeSubscribers: [String: [UUID: MessageHandler]] = [:]
    private let subscriberLock = NSLock()
    
    // MARK: - Message Queue (for messages sent before connected)
    private var pendingMessages: [[String: Any]] = []
    private var hasIdentified = false
    
    // MARK: - Reconnection
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var reconnectTimer: Timer?
    
    init(serverURL: String = SocketService.defaultServerURL) {
        self.serverURL = serverURL
        self.deviceId = UserDefaults.standard.string(forKey: "deviceId") ?? {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: "deviceId")
            return id
        }()
        
        // Listen for app lifecycle
        setupLifecycleObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Lifecycle Handling
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleAppWillResignActive() {
        // Don't disconnect immediately - just stop reconnect attempts
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    @objc private func handleAppDidBecomeActive() {
        if !isConnected && socket != nil {
            attemptReconnect()
        }
    }
    
    // MARK: - Connection Management
    func connect() {
        guard socket == nil else { return }
        
        manager = SocketManager(socketURL: URL(string: serverURL)!, config: [
            .log(false),
            .compress,
            .forceWebsockets(true),
            .forceNew(true),
            .reconnects(false) // We handle reconnection ourselves
        ])
        
        socket = manager?.defaultSocket
        
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self = self else { return }
            Log.socket("Connected to server")
            self.reconnectAttempts = 0
            // Send hello FIRST, before setting isConnected
            self.sendHelloAndFlushQueue()
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            guard let self = self else { return }
            Log.socket("Disconnected from server")
            DispatchQueue.main.async {
                self.isConnected = false
                self.hasIdentified = false
            }
            self.scheduleReconnect()
        }
        
        socket?.on(clientEvent: .error) { [weak self] data, _ in
            Log.socketError("Socket error: \(data)")
            self?.scheduleReconnect()
        }
        
        socket?.on("message") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let type = dict["type"] as? String else { return }
            Log.socket("Received: \(type)")
            self?.routeMessage(type: type, data: dict)
        }
        
        socket?.connect()
    }
    
    private func sendHelloAndFlushQueue() {
        // Send hello synchronously on socket thread
        let helloMessage: [String: Any] = [
            "type": "hello",
            "version": "1.1.0",
            "deviceId": deviceId,
            "playerName": UserDefaults.standard.string(forKey: "playerName") ?? "Anonymous"
        ]
        socket?.emit("message", helloMessage)
        
        // Now mark as connected and flush pending messages
        DispatchQueue.main.async { [weak self] in
            self?.hasIdentified = true
            self?.isConnected = true
            self?.flushPendingMessages()
        }
    }
    
    private func flushPendingMessages() {
        for message in pendingMessages {
            socket?.emit("message", message)
        }
        pendingMessages.removeAll()
    }
    
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            Log.socket("Max reconnect attempts reached")
            return
        }
        
        reconnectTimer?.invalidate()
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // Exponential backoff, max 30s
        reconnectAttempts += 1
        
        Log.socket("Scheduling reconnect attempt \(reconnectAttempts) in \(delay)s")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.attemptReconnect()
        }
    }
    
    private func attemptReconnect() {
        guard !isConnected else { return }
        Log.socket("Attempting reconnect...")
        socket?.connect()
    }
    
    // MARK: - Pub/Sub Message Routing
    
    /// Subscribe to ALL messages (for global handlers like GameState)
    func subscribe(handler: @escaping MessageHandler) -> MessageSubscription {
        let id = UUID()
        subscriberLock.lock()
        subscribers[id] = handler
        subscriberLock.unlock()
        return MessageSubscription(id: id, service: self)
    }
    
    /// Subscribe to specific message types only
    func subscribe(to types: [String], handler: @escaping MessageHandler) -> MessageSubscription {
        let id = UUID()
        subscriberLock.lock()
        for type in types {
            if typeSubscribers[type] == nil {
                typeSubscribers[type] = [:]
            }
            typeSubscribers[type]?[id] = handler
        }
        subscriberLock.unlock()
        return MessageSubscription(id: id, service: self)
    }
    
    fileprivate func unsubscribe(id: UUID) {
        subscriberLock.lock()
        subscribers.removeValue(forKey: id)
        for type in typeSubscribers.keys {
            typeSubscribers[type]?.removeValue(forKey: id)
        }
        subscriberLock.unlock()
    }
    
    private func routeMessage(type: String, data: [String: Any]) {
        subscriberLock.lock()
        let globalHandlers = Array(subscribers.values)
        let typeHandlers = typeSubscribers[type]?.values.map { $0 } ?? []
        subscriberLock.unlock()
        
        // Dispatch to main thread for UI updates
        DispatchQueue.main.async {
            // Notify all global subscribers
            for handler in globalHandlers {
                handler(type, data)
            }
            // Notify type-specific subscribers
            for handler in typeHandlers {
                handler(type, data)
            }
        }
    }
    
    // MARK: - Send Messages (Queued if not connected)
    
    func send(_ message: [String: Any]) {
        guard hasIdentified else {
            Log.socket("Queuing message (not yet identified): \(message["type"] ?? "unknown")")
            pendingMessages.append(message)
            return
        }
        socket?.emit("message", message)
    }
    
    func queue(mode: Int, matchType: String, botDifficulty: String? = nil, kidsMode: [String: Any]? = nil) {
        var msg: [String: Any] = [
            "type": "queue",
            "mode": mode,
            "matchType": matchType
        ]
        if let difficulty = botDifficulty {
            msg["botDifficulty"] = difficulty
        }
        // Add kids mode settings for safe matchmaking
        if let kidsSettings = kidsMode {
            msg["kidsMode"] = kidsSettings
        }
        send(msg)
    }
    
    func submitWord(_ word: String) {
        send([
            "type": "submit",
            "word": word
        ])
    }
    
    func leave() {
        send(["type": "leave"])
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        socket?.disconnect()
        socket = nil
        manager = nil
        hasIdentified = false
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
}
