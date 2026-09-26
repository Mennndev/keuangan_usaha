import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private var backupChannel: FlutterMethodChannel?
  private var backupResult: FlutterResult?
  private var saveResult: FlutterResult?
  private var pendingBackupURL: URL?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BackupPicker")
    let channel = FlutterMethodChannel(name: "keuangan_usaha/backup", binaryMessenger: registrar.messenger())
    backupChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "saveBackup" {
        guard let self,
              self.backupResult == nil,
              self.saveResult == nil,
              let args = call.arguments as? [String: Any],
              let bytes = (args["bytes"] as? FlutterStandardTypedData)?.data,
              let fileName = args["fileName"] as? String,
              let presenter = self.window?.rootViewController else {
          result(FlutterError(code: "invalid", message: "Isi file cadangan tidak valid.", details: nil))
          return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
          try bytes.write(to: url, options: .atomic)
          self.pendingBackupURL = url
          self.saveResult = result
          let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
          picker.delegate = self
          presenter.present(picker, animated: true)
        } catch {
          result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
        }
        return
      }
      guard call.method == "openBackup" else { result(FlutterMethodNotImplemented); return }
      guard let self, self.backupResult == nil,
            let presenter = self.window?.rootViewController else {
        result(FlutterError(code: "busy", message: "Pemilih file tidak tersedia.", details: nil))
        return
      }
      self.backupResult = result
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
      picker.delegate = self
      presenter.present(picker, animated: true)
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    if let result = saveResult {
      saveResult = nil
      pendingBackupURL = nil
      result(true)
      return
    }
    defer { backupResult = nil }
    guard let url = urls.first else { backupResult?(nil); return }
    let accessed = url.startAccessingSecurityScopedResource()
    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
    do {
      let data = try Data(contentsOf: url)
      backupResult?(["bytes": FlutterStandardTypedData(bytes: data)])
    } catch {
      backupResult?(FlutterError(code: "read_failed", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    if let result = saveResult {
      saveResult = nil
      pendingBackupURL = nil
      result(false)
      return
    }
    backupResult?(nil)
    backupResult = nil
  }
}
