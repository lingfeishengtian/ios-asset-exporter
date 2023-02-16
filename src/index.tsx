import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-ios-assset-exporter' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

export enum PhotoAssetErrors {
  noAssetsFound,
  destinationNotAccessible,
}

export enum PhotoAssetWarnings {
  duplicateIdentifiersRemoved,
  destinationFileAlreadyExists,
  blacklistedExtension,
  noDeletionNecesary,
}

export type ExportedAssetResource = {
  associatedAssetID: string
  localFileLocations: string
  warning: PhotoAssetWarnings[]
}

export type PhotoAssetResults = {
  error?: PhotoAssetErrors[],
  general?: PhotoAssetWarnings[],
  exportResults?: ExportedAssetResource[]
}

const AssetExporter = NativeModules.AssetExporter
  ? NativeModules.AssetExporter
  : new Proxy(
    {},
    {
      get() {
        throw new Error(LINKING_ERROR);
      },
    }
  );

export async function exportPhotoAssets(
  photoIdentifiers: [string],
  exportPath: string,
  withPrefix: string,
  shouldRemoveExistingFile: boolean,
  ignoreBlacklist: boolean): Promise<PhotoAssetResults> {
  return new Promise((resolve, reject) => {
    AssetExporter.exportPhotoAssets(photoIdentifiers, exportPath, withPrefix, shouldRemoveExistingFile, ignoreBlacklist,
      (results: string) => {
        try {
          resolve(JSON.parse(results) as PhotoAssetResults)
        } catch (e) {
          reject(e)
        }
      });
  });
}