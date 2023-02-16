//
//  AssetExporter.swift
//  Filen
//
//  Created by Hunter Han on 2/15/23.
//
import Foundation
import Photos

@objc(AssetExporter) class AssetExporter: NSObject {
  @objc enum PhotoAssetErrors: Int, Codable {
    case noAssetsFound
    case destinationNotAccessible
  }
  
  @objc enum PhotoAssetWarnings: Int, Codable {
    case duplicateIdentifiersRemoved
    case destinationFileAlreadyExists
    case blacklistedExtension
    case noDeletionNecesary
  }
  
  struct ExportedAssetResource: Codable {
    var associatedAssetID: String
    var localFileLocations: String
    var warning: [PhotoAssetWarnings] = []
  }
  
  struct AssetReturnResult: Codable {
    var error: [PhotoAssetErrors] = []
    var general: [PhotoAssetWarnings] = []
    var exportResults: [ExportedAssetResource] = []
    
    mutating func appendResource(resource: ExportedAssetResource) {
      self.exportResults.append(resource)
    }
    
    mutating func appendWarning(warn: PhotoAssetWarnings){
      self.general.append(warn)
    }
  }
  
  let BLACKLISTED_EXTENSIONS = ["plist"]
  
  @objc func exportPhotoAssets(_ withIdentifiers: [String], to: String, withPrefix: String, shouldRemoveExistingFile: Bool, ignoreBlacklist: Bool, callback: @escaping RCTResponseSenderBlock) {
    if #available(iOS 13, *) {
      Task{
        await self._exportPhotoAssets(withIdentifiers, to: to, withPrefix: withPrefix, shouldRemoveExistingFile: shouldRemoveExistingFile, ignoreBlacklist: ignoreBlacklist, callback: callback)
      }
    } else {
        callback([["error": "iOS 13 or later is required to use this function"]])
    }
  }
  
  func _exportPhotoAssets(_ withIdentifiers: [String], to: String, withPrefix: String, shouldRemoveExistingFile: Bool, ignoreBlacklist: Bool, callback: @escaping RCTResponseSenderBlock) async -> Void {
    let encoder = JSONEncoder()
    var returnValue:AssetReturnResult = AssetReturnResult()
    
    if !FileManager.default.fileExists(atPath: to) || !FileManager.default.isWritableFile(atPath: to){
      returnValue.error.append(PhotoAssetErrors.destinationNotAccessible)
      //      return String(data: try encoder.encode(returnValue), encoding: .utf8)!
      do{
        callback([String(data: try encoder.encode(returnValue), encoding: .utf8)!])
      } catch {
        callback([["error": "Couldn't parse: " + error.localizedDescription]])
      }
      
      return
    }
    
    let identifierSet = Set(withIdentifiers)
    if withIdentifiers.count != withIdentifiers.count {
      returnValue.appendWarning(warn: PhotoAssetWarnings.duplicateIdentifiersRemoved)
    }
    
    let fetchOptions = PHFetchOptions()
    fetchOptions.includeAllBurstAssets = true
    fetchOptions.includeHiddenAssets = true
    let queriedAssets = PHAsset.fetchAssets(withLocalIdentifiers: Array(identifierSet), options: fetchOptions)
    if queriedAssets.count <= 0{
      returnValue.error.append(PhotoAssetErrors.noAssetsFound)
      //      return String(data: try encoder.encode(returnValue), encoding: .utf8)!
      do{
        callback([String(data: try encoder.encode(returnValue), encoding: .utf8)!])
      } catch {
        callback([["error": "Couldn't parse: " + error.localizedDescription]])
      }
      return
    }
    // Exported files with nil will be ones that didn't exist in iOS photo library
    
    let options: PHAssetResourceRequestOptions = PHAssetResourceRequestOptions()
    options.isNetworkAccessAllowed = true
    
    if #available(iOS 13, *) {
    await withTaskGroup(of: ExportedAssetResource.self, body: {
      group in
      var exported = [ExportedAssetResource]()
      exported.reserveCapacity(queriedAssets.count)
      
      for i in 0..<queriedAssets.count{
        let queried = queriedAssets.object(at: i)
        var assetResources: [PHAssetResource] = []
        if let burstId = queried.burstIdentifier {
          print(burstId)
          let queriedBurstAssets = PHAsset.fetchAssets(withBurstIdentifier: burstId, options: fetchOptions)
          queriedBurstAssets.enumerateObjects({
            (burstAsset, ind, stop) -> Void in
            assetResources.append(contentsOf: PHAssetResource.assetResources(for: burstAsset))
          })
        } else {
          assetResources = PHAssetResource.assetResources(for: queried)
        }
        
        for asset in assetResources {
          print(asset.originalFilename)
          
          
          let fileExtension: String = URL(fileURLWithPath: asset.originalFilename).pathExtension
          if !(!ignoreBlacklist && BLACKLISTED_EXTENSIONS.contains(fileExtension.lowercased())) {
            group.addTask {
              let destination = URL(fileURLWithPath: to + "/" + withPrefix + asset.originalFilename).deletingPathExtension().appendingPathExtension(fileExtension)
              var newAssetResource = ExportedAssetResource(associatedAssetID: asset.assetLocalIdentifier, localFileLocations: destination.absoluteString)
              
              if (shouldRemoveExistingFile) {
                do {
                  try FileManager.default.removeItem(at: destination)
                } catch {
                  newAssetResource.warning.append(PhotoAssetWarnings.noDeletionNecesary)
                }
              }
              
              do {
                try await PHAssetResourceManager.default().writeData(for: asset, toFile: destination, options: options)
              } catch {
                newAssetResource.warning.append(PhotoAssetWarnings.destinationFileAlreadyExists)
              }
              return newAssetResource
            }
          }
        }
      }
      
      for await resource in group {
        returnValue.appendResource(resource: resource)
      }
    })
    } else {
        callback([["error": "iOS 13 or later is required to use this function"]])
        
        return
    }
    
    do{
      callback([String(data: try encoder.encode(returnValue), encoding: .utf8)!])
    } catch {
      callback([["error": "Couldn't parse: " + error.localizedDescription]])
    }
    return
  }
}
