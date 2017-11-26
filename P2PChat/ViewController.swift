//
//  ViewController.swift
//  P2PChat
//
//  Created by Yuta on 2017/11/25.
//  Copyright © 2017年 Yuta. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate , UITextFieldDelegate{

    let serviceType = "P2PChat"
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    var session: MCSession!
    var peerID: MCPeerID!
    var connected: Bool = false

    @IBOutlet weak var browseButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var messageView: UITextView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        messageView.isEditable = false
        textField.delegate = self

        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID)
        session.delegate = self

        assistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: session)
        assistant.start()

        browser = MCBrowserViewController(serviceType: serviceType, session: session)
        browser.delegate = self
    }

    @IBAction func pushBrowseButton(_ sender: Any) {
        self.present(self.browser, animated: true, completion: nil)
    }

    @IBAction func sendButton(_ sender: Any) {
        sendMessage()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
    
    func sendMessage(){
        if !(textField.text?.isEmpty)! && sendMessageData() {
            updateChat(text: textField.text!, fromPeer: peerID)
            textField.text = ""
            textField.resignFirstResponder()
            scrollView.contentOffset.y = 0
        }
    }

    func sendMessageData() -> Bool {
        let message = textField.text?.data(using: String.Encoding.utf8)
        do {
            try session.send(message!, toPeers: session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            popAlert(title: "送信に失敗しました", message: "もう一度送信してください")
            return false
        }
        return true
    }

    func updateChat(text: String, fromPeer peerID: MCPeerID) {
        var name: String
        switch peerID {
            case self.peerID:
                name = "あなた"
            default:
                name = peerID.displayName
        }
        let message = "\(name): \(text)\n"
        messageView.text = messageView.text! + message
    }

    //ピアの状態が変更された
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            print("接続に失敗しました")
            popAlert(title: "接続に失敗しました", message: "もう一度接続を試みてください")
        case .connecting:
            print("接続中です")
        case .connected:
            print("接続完了")
            DispatchQueue.main.async {
                self.connected = true
                self.dismiss(animated: true, completion: nil)
                self.displayChange()
            }
        }
    }

    // データを受信した
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            let msg = String(data: data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            self.updateChat(text: msg!, fromPeer: peerID)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Called when a nearby peer opens a byte stream connection to the local peer.
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Indicates that the local peer began receiving a resource from a nearby peer.
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
         // Indicates that the local peer finished receiving a resource from a nearby peer.
    }
    // Doneボタン押下
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    // Cancelボタン押下
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        self.dismiss(animated: true, completion: nil)
    }

    // textFieldをキーボードの上まで持ってくる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.keyboardWillShowNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.keyboardWillHideNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    @objc func keyboardWillShowNotification(_ notification: Notification) {
        let userInfo = notification.userInfo!
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let myBoundSize: CGSize = UIScreen.main.bounds.size
        let txtLimit = textField.frame.origin.y + textField.frame.height + 30.0
        let kbdLimit = myBoundSize.height - keyboardScreenEndFrame.size.height
        if txtLimit >= kbdLimit {
            scrollView.contentOffset.y = txtLimit - kbdLimit
        }
    }

    @objc func keyboardWillHideNotification(_ notification: Notification) {
        scrollView.contentOffset.y = 0
    }

    func displayChange() {
        if connected {
            lineView.isHidden = !lineView.isHidden
            sendButton.isHidden = !sendButton.isHidden
            scrollView.isHidden = !scrollView.isHidden
            browseButton.isHidden = !browseButton.isHidden
            messageView.isHidden = !messageView.isHidden
            textField.isHidden = !textField.isHidden
        }
    }

    func popAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title,message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler:{(action: UIAlertAction) in
          print("ok")
        })
        alertController.addAction(okAction)
        present(alertController,animated: true,completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


