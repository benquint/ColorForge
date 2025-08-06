
//
//  LoadingModel.swift
//  ColorForge Enlarger
//
//  Created by Ben Quinton on 04/02/2025.
//

import Foundation
import AppKit
import SwiftUI
import ImageProcessing

class LoadingModel: ObservableObject {
	
	// MARK: - Loading Booleans
	var isLoading: Bool = false
	var loadingTempAndTint: Bool = false
	var hasLoadedEmbeddedPreviews: Bool = true
	var hasLoadedCIImage: Bool = true
	@Published var isFullyLoaded: Bool = true  {
		didSet {
			imageProcessingModel.loadingModelComplete = isFullyLoaded
		}
	}
	var rawsLoaded: Bool = false {
		didSet {
			imageProcessingModel.rawsLoaded = rawsLoaded
		}
	}
	
	@Published var loadingModelComplete: Bool = false
	@Published var completedPreviews: Int = 0
	@Published var totalPreviews: Int = 0
	
	let imageProcessingModel: ImageProcessingModel
	let imageProcessingMain: ImageProcessingMain
	let imageProcessingBackground: ImageProcessingBackground
    let dataModel: DataModel
	
    init(imageProcessingMain: ImageProcessingMain, imageProcessingModel: ImageProcessingModel, imageProcessingBackground: ImageProcessingBackground, dataModel: DataModel) {
		self.imageProcessingMain = imageProcessingMain
		self.imageProcessingBackground = imageProcessingBackground
		self.imageProcessingModel = imageProcessingModel
        self.dataModel = dataModel
	}
	
	private let fileManager = FileManager.default
	
	/// Handles file import and updates the `DataModel`.
	func openAndImportFiles(dataModel: DataModel) {
		
		// Open files using NSOpenPanel
		fileManager.openFiles { [weak self] selectedURLs in
			guard let self = self else { return }
			guard !selectedURLs.isEmpty else {
				DispatchQueue.main.async {
					self.hasLoadedEmbeddedPreviews = false // Stop loading if no files selected
				}
				return
			}
			
			
			// Process files in the background
			DispatchQueue.global(qos: .userInitiated).async {
				self.processSelectedFiles(selectedURLs, dataModel: dataModel) {
					// Background processing AFTER all previews and debayering complete
					DispatchQueue.main.async {
						let idsToProcess = dataModel.rawImages
							.filter { $0.isRawFile && $0.rawDataUi != nil }
							.map { $0.id }

						self.imageProcessingModel.initialProcessingIDs = idsToProcess
					}
				}
			}
		}
	}
	
	/// Processes the selected files, extracts metadata, saves previews, and updates the `DataModel'

	
//	private func processSelectedFiles(_ urls: [URL], dataModel: DataModel) {
	private func processSelectedFiles(_ urls: [URL], dataModel: DataModel, completion: @escaping () -> Void) {
		hasLoadedCIImage = false
		isLoading = true

		DispatchQueue.main.async {
			self.isFullyLoaded = false
			self.totalPreviews = urls.count
			self.completedPreviews = 0
		}

		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"
		let importFolderName = dateFormatter.string(from: Date())

		guard let appSupportDirectory = fileManager.applicationSupportDirectory else {
			DispatchQueue.main.async { self.hasLoadedEmbeddedPreviews = false }
			return
		}

		let baseImportFolder = appSupportDirectory.appendingPathComponent("ColorForgeEnlarger/ImageCache/\(importFolderName)", isDirectory: true)
		let imageCacheFolder = baseImportFolder.appendingPathComponent("ImageCache", isDirectory: true)
		let thumbnailCacheFolder = baseImportFolder.appendingPathComponent("ThumbnailCache", isDirectory: true)

		fileManager.createDirectoryIfNeeded(at: baseImportFolder)
		fileManager.createDirectoryIfNeeded(at: imageCacheFolder)
		fileManager.createDirectoryIfNeeded(at: thumbnailCacheFolder)

		// Step 1: Create RawImage structs and insert into dataModel
		let initialRawImages: [RawImage] = urls.map { url in
			let name = url.deletingPathExtension().lastPathComponent
			let dateCreated = (try? fileManager.attributesOfItem(atPath: url.path)[.creationDate] as? Date) ?? Date()
			let fileExtension = url.pathExtension.lowercased()
			let isRaw = isRawFile(fileExtension: fileExtension)

			return RawImage(
				rawUrl: url,
				name: name,
				dateCreated: dateCreated,
				isRawFile: isRaw,
				uiImageCacheUrl: imageCacheFolder.appendingPathComponent("\(name).jpg"),
				thumbnailCacheUrl: thumbnailCacheFolder.appendingPathComponent("\(name).jpg"),
				importFolderName: importFolderName,
				isCachedImage: false,
				isPreview: false
			)
		}

		DispatchQueue.main.async {
			dataModel.rawImages.append(contentsOf: initialRawImages)
			dataModel.sortByDateCreated()
			
			for image in dataModel.rawImages {
				print("🧩 Stored rawImage: \(image.name ?? "Unnamed"), URL: \(image.rawUrl?.absoluteString ?? "nil")")
			}
		}

		let previewGroup = DispatchGroup()
		let debayerGroup = DispatchGroup()

		// Step 2a: Start concurrent preview loading
		for rawImage in initialRawImages {
			guard let url = rawImage.rawUrl else { continue }
			let name = rawImage.name ?? ""

			if let cachedData = AppDataManager.shared.getCachedImage(url: url),
			   let cachedImage = NSImage(contentsOf: imageCacheFolder.appendingPathComponent("\(name).jpg")) {
				DispatchQueue.main.async {
					if let i = dataModel.rawImages.firstIndex(where: { $0.rawUrl == url }) {
						dataModel.rawImages[i].previewImage = cachedImage
						dataModel.rawImages[i].isPreview = true
						dataModel.rawImages[i].isCachedImage = true
					}
					self.completedPreviews += 1
					print("Cached preview: \(name)")
				}
			} else {
				previewGroup.enter()
				fileManager.extractPreview(from: url) { [weak self] previewImage, dateCreated in
					guard let self = self, let previewImage = previewImage else {
						previewGroup.leave()
						return
					}

					self.fileManager.savePreview(previewImage: previewImage, to: imageCacheFolder, with: name) { cacheURL in
						guard let cacheURL = cacheURL else {
							previewGroup.leave()
							return
						}

						let appDataEntry = AppData(id: rawImage.id, rawUrl: url, importFolder: importFolderName)
						AppDataManager.shared.addImageToCache(appData: appDataEntry)

						DispatchQueue.main.async {
							if let i = dataModel.rawImages.firstIndex(where: { $0.rawUrl == url }) {
								dataModel.rawImages[i].previewImage = previewImage
								dataModel.rawImages[i].uiImageCacheUrl = cacheURL
								dataModel.rawImages[i].isPreview = true
								dataModel.rawImages[i].isCachedImage = false
							}
							
							
							print("Extracted preview: \(name)")
							previewGroup.leave()
						}
					}
				}
			}
		}

		// Step 2b: Start concurrent debayering
		for image in initialRawImages where image.isRawFile && image.rawUrl != nil {
			debayerGroup.enter()
			var debayeringImage = image

			DispatchQueue.global(qos: .userInitiated).async {
				if let debayered = self.debayerImage(for: &debayeringImage) {
					DispatchQueue.main.async {
						if let i = dataModel.rawImages.firstIndex(where: { $0.id == debayeringImage.id }) {
							dataModel.rawImages[i].rawDataUi = debayered
							self.imageProcessingModel.processAndDisplayBackgroundInit(id: debayeringImage.id)
							self.completedPreviews += 1
						}
					}
				} else {
					print("Debayer failed: \(image.name ?? "Unnamed")")
				}
				debayerGroup.leave()
			}
		}


		// Step 3: When both tasks complete
		let completionGroup = DispatchGroup()
		completionGroup.enter()
		completionGroup.enter()

		previewGroup.notify(queue: .main) {
			print("✅ All previews processed.")
//			self.isLoading = false
			completionGroup.leave()
		}
		


		debayerGroup.notify(queue: .main) {
			self.rawsLoaded = true
			self.hasLoadedCIImage = true
			print("✅ All debayering complete.")
			completionGroup.leave()
		}

		completionGroup.notify(queue: .main) {
			self.isLoading = false
			self.isFullyLoaded = true
			self.loadingModelComplete = true
			completion()
		}
	}
	
	
//
//	private func processSelectedFiles(_ urls: [URL], dataModel: DataModel) {
//		hasLoadedCIImage = false
//		isLoading = true // Start loading
//		
//		DispatchQueue.main.async {
//			self.isFullyLoaded = false
//		}
//		
//		let dateFormatter = DateFormatter()
//		dateFormatter.dateFormat = "yyyy-MM-dd"
//		let importFolderName = dateFormatter.string(from: Date())
//		
//		DispatchQueue.main.async{
//			self.totalPreviews = urls.count
//			self.completedPreviews = 0
//		}
//		
//		guard let appSupportDirectory = fileManager.applicationSupportDirectory else {
//			DispatchQueue.main.async { self.hasLoadedEmbeddedPreviews = false }
//			return
//		}
//		
//		let baseImportFolder = appSupportDirectory.appendingPathComponent("ColorForgeEnlarger/ImageCache/\(importFolderName)", isDirectory: true)
//		let imageCacheFolder = baseImportFolder.appendingPathComponent("ImageCache", isDirectory: true)
//		let thumbnailCacheFolder = baseImportFolder.appendingPathComponent("ThumbnailCache", isDirectory: true)
//		
//		fileManager.createDirectoryIfNeeded(at: baseImportFolder)
//		fileManager.createDirectoryIfNeeded(at: imageCacheFolder)
//		fileManager.createDirectoryIfNeeded(at: thumbnailCacheFolder)
//		
//		var importedImages: [RawImage] = []
//		let group = DispatchGroup()
//		
//		// Step 1: Extract Previews
//		for url in urls {
//            let fileExtension = url.pathExtension.lowercased()
//            let isRaw = isRawFile(fileExtension: fileExtension)
//            
//			if let cachedData = AppDataManager.shared.getCachedImage(url: url) {
//				let cachedImageURL = imageCacheFolder.appendingPathComponent("\(url.deletingPathExtension().lastPathComponent).jpg")
//				let cachedImage = NSImage(contentsOf: cachedImageURL)
//				
//				let dateCreated = (try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate] as? Date) ?? Date()
//				
//				let rawImage = RawImage(
//					rawUrl: url,
//					name: url.deletingPathExtension().lastPathComponent,
//					dateCreated: dateCreated,
//					previewImage: cachedImage,
//                    isRawFile: isRaw,
//					uiImageCacheUrl: cachedImageURL,
//					thumbnailCacheUrl: thumbnailCacheFolder.appendingPathComponent("\(url.deletingPathExtension().lastPathComponent).jpg"),
//					importFolderName: cachedData.importFolder,
//					isCachedImage: true,
//					isPreview: true
//                    
//				)
//				importedImages.append(rawImage)
//				
//				DispatchQueue.main.async {
//					self.completedPreviews += 1
//					print("Cached image found. Completed Previews = \(self.completedPreviews)")
//				}
//				
//				continue
//			}
//			
//			
//			group.enter()
//			
//			fileManager.extractPreview(from: url) { [weak self] previewImage, dateCreated in
//				guard let self = self, let previewImage = previewImage else {
//					group.leave()
//					return
//				}
//				
//				let name = url.deletingPathExtension().lastPathComponent
//				self.fileManager.savePreview(previewImage: previewImage, to: imageCacheFolder, with: name){_ in }
//				
//				self.fileManager.savePreview(previewImage: previewImage, to: imageCacheFolder, with: name) { cacheURL in
//					guard let cacheURL = cacheURL else {
//						group.leave()
//						return
//					}
//					
//					let rawImage = RawImage(
//						rawUrl: url,
//						name: name,
//						dateCreated: dateCreated,
//						previewImage: previewImage,
//                        isRawFile: isRaw,
//						uiImageCacheUrl: cacheURL,
//						thumbnailCacheUrl: thumbnailCacheFolder.appendingPathComponent("\(name).jpg"),
//						importFolderName: importFolderName,
//						isCachedImage: false,
//						isPreview: true
//					)
//					let appDataEntry = AppData(id: rawImage.id, rawUrl: url, importFolder: importFolderName)
//					AppDataManager.shared.addImageToCache(appData: appDataEntry)
//					
//
//					
//					importedImages.append(rawImage)
//					DispatchQueue.main.async{
//						self.completedPreviews += 1
//						print("Completed Previews = \(self.completedPreviews)")
//						group.leave()
//					}
//					
//				}
//			}
//		}
//		
//		
//		
//		group.notify(queue: .main) {
//			dataModel.rawImages.append(contentsOf: importedImages)
//			dataModel.sortByDateCreated()
//			
//			if self.completedPreviews == self.totalPreviews {
//				self.isLoading = false
//			}
//			
//			// Step 2: Debayer raw images
//			
//			DispatchQueue.global(qos: .userInitiated).async {
//                
//                
//				let debayerGroup = DispatchGroup()
//				
//                for var rawImage in dataModel.rawImages { // Change `let` to `var`
//                    guard rawImage.isRawFile, let rawUrl = rawImage.rawUrl else { continue }
//
//                    debayerGroup.enter()
//                    if let debayeredImage = self.debayerImage(for: &rawImage) { // Pass as inout
//                        DispatchQueue.main.async {
//                            if let index = dataModel.rawImages.firstIndex(where: { $0.id == rawImage.id }) {
//                                dataModel.rawImages[index].rawDataUi = debayeredImage
//                            }
//                        }
//                    } else {
//                        print("Failed to debayer image for URL: \(rawUrl).")
//                    }
//                    debayerGroup.leave()
//                }
//				
//				
//				// Process Full Res
//				
//				debayerGroup.notify(queue: .global(qos: .background)) {
//					DispatchQueue.main.async{
//						self.rawsLoaded = true
//					}
//					
//					DispatchQueue.main.async{
//						self.hasLoadedCIImage = true
//					}
//					
//					
//					
//					let fullResolutionGroup = DispatchGroup()
//					
//					// Temporary Debug
//					fullResolutionGroup.enter()
//					
//					// Move this logic to loading images singularily
//					
////					for rawImage in dataModel.rawImages {
////						guard let rawUrl = rawImage.rawUrl else { continue }
////						
////						fullResolutionGroup.enter()
////						DispatchQueue.global(qos: .background).async {
////							if let fullResolutionImage = self.loadFullResolutionImage(from: rawUrl) {
////								DispatchQueue.main.async {
////									if let index = dataModel.rawImages.firstIndex(where: { $0.id == rawImage.id }) {
////										dataModel.rawImages[index].rawDataFull = fullResolutionImage
////										dataModel.rawImages[index].fullImageExtent = fullResolutionImage.extent
////										dataModel.rawImages[index].totalRows512 = Int(ceil(fullResolutionImage.extent.height / 512))
////										dataModel.rawImages[index].totalColumns512 = Int(ceil(fullResolutionImage.extent.width / 512))
//////										print("Loaded full-resolution image for \(rawImage.name).")
////									}
////								}
////							} else {
////								print("Failed to load full-resolution image for \(rawImage.name).")
////							}
////
////							fullResolutionGroup.leave()
////						}
////					}
//					
//					// Temporary Debug
//					fullResolutionGroup.leave()
//					
//					fullResolutionGroup.notify(queue: .main) {
//						self.isFullyLoaded = true
//						print("All full-resolution images have been loaded.")
//					}
//					
//				}
//
//				
//			}
//		}
//		DispatchQueue.main.async{
////			self.isFullyLoaded = true
//			self.loadingModelComplete = true
//		}
//	}

	
	// MARK: - Debayer

	
    func debayerImage(for rawImage: inout RawImage) -> CIImage? {
        guard let rawUrl = rawImage.rawUrl else {
            print("Invalid RAW image URL.")
            return nil
        }
        
        // Extract camera information
        let cameraInfo = extractCameraInfo(from: rawUrl)

		// Explicitly update the values, even if they are false
		rawImage.isCanon = cameraInfo.isCanon ? true : false
		rawImage.isGFX100s = cameraInfo.isGFX100s ? true : false
		rawImage.isNikon = cameraInfo.isNikon ? true : false
		rawImage.iso = cameraInfo.iso
		rawImage.fStop = cameraInfo.fStop
		rawImage.shutterSpeed = cameraInfo.shutterSpeed
		rawImage.cameraMake = cameraInfo.cameraModel
		
		// Print extracted metadata
		print("""
		\nExtracted Metadata:
		ISO: \(rawImage.iso)
		f-Stop: \(rawImage.fStop)
		Shutter Speed: \(rawImage.shutterSpeed)
		Camera Make: \(rawImage.cameraMake)
		""")

        // Ensure this is a RAW file before processing
        let fileExtension = rawUrl.pathExtension.lowercased()
        guard isRawFile(fileExtension: fileExtension) else {
            print("Skipping non-RAW file: \(rawUrl.lastPathComponent)")
            return nil
        }
		rawImage.isRawFile = true

        guard let rawFilter = CIRAWFilter(imageURL: rawUrl) else {
            print("Failed to create CIRAWFilter for \(rawUrl).")
            return nil
        }

        // Extract RAW dimensions and update struct
        let rawExtent = rawFilter.nativeSize
        rawImage.rawExtentX = Int(rawExtent.width)
        rawImage.rawExtentY = Int(rawExtent.height)
		
		let x = rawFilter.neutralChromaticity.x
		let y = rawFilter.neutralChromaticity.y

        // Now calculate raw scale
        calculateRawScale(for: &rawImage)

        let scopeScale = 0.3

//        rawFilter.baselineExposure = 0.0
		rawFilter.isLensCorrectionEnabled = true
        rawFilter.shadowBias = 0.0
        rawFilter.boostAmount = 0.0
        rawFilter.localToneMapAmount = 0.0
        rawFilter.isGamutMappingEnabled = false
        rawFilter.extendedDynamicRangeAmount = 0.0
        rawFilter.scaleFactor = rawImage.rawScale ?? 0.25
        rawFilter.boostShadowAmount = 0.0
        rawFilter.contrastAmount = 0.0
        rawFilter.detailAmount = 0.0
        rawFilter.exposure = 0.0
        rawFilter.sharpnessAmount = 0.0

        guard let ciRawImage = rawFilter.outputImage else {
            print("Failed to generate image from RAW file.")
            return nil
        }
		
		print("""
\n \n \n
Neutral Temp = \(rawFilter.neutralTemperature)
\n
Neutral Tint = \(rawFilter.neutralTint)
\n
Neutral Chromaticity XY = \(rawFilter.neutralChromaticity)
\n
Baseline exposure amount = \(rawFilter.baselineExposure)

\n \n \n
""")
        
		self.imageProcessingModel.loadSettingsFromXMP(for: rawUrl)
		
        // Determine if the image is landscape (width > height) or portrait (height > width)
        if let rawScale = rawImage.rawScale, rawScale > 0 {
            rawImage.fullRotatedWidth = Int(ciRawImage.extent.width / CGFloat(rawScale))
            rawImage.fullRotatedHeight = Int(ciRawImage.extent.height / CGFloat(rawScale))
        } else {
//            print("Warning: rawScale is nil or zero, defaulting fullRotatedWidth and fullRotatedHeight to 0.")
            rawImage.fullRotatedWidth = 0
            rawImage.fullRotatedHeight = 0
        }
        
        rawImage.uiWidth = ciRawImage.extent.width
        rawImage.uiHeight = ciRawImage.extent.height
        
        if let rawScale = rawImage.rawScale {
            rawImage.fullRotatedWidth = Int(ciRawImage.extent.width / CGFloat(rawScale))
            rawImage.fullRotatedHeight = Int(ciRawImage.extent.height / CGFloat(rawScale))
        } else {
            rawImage.fullRotatedWidth = 0
            rawImage.fullRotatedHeight = 0
        }

        if let fileName = rawImage.rawUrl?.lastPathComponent {
            let orientation = rawImage.rawRotation == 1 ? "Portrait" : "Landscape"

        } else {
            print("Warning: Unable to extract filename for raw image.")
        }
		
		let onePixelImage = ciRawImage.cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
		
		let tempFromXY = ImageProcessingModel.TempTintFromXY()
		tempFromXY.inputImage = onePixelImage // Irelevant
		tempFromXY.x = Float(rawFilter.neutralChromaticity.x)
		tempFromXY.y = Float(rawFilter.neutralChromaticity.y)
		guard let tempTintImage = tempFromXY.outputImage else {return nil}
		
		guard let (temp, tint) = imageProcessingModel.extractFloat2Value(from: tempTintImage) else {return nil}
		
		print("\nLoadingModel:\nX: \(rawFilter.neutralChromaticity.x),\nY: \(rawFilter.neutralChromaticity.y),\nTemp: \(temp),\nTint: \(tint)\n")

		rawImage.InitrawTemp = temp
		rawImage.InitrawTint = tint
		rawImage.rawTemp = temp
		rawImage.rawTint = tint
        
        let cachedRawImage = ciRawImage/*.insertingIntermediate(cache: true)*/

        var scopeTransform = CGAffineTransform.identity
        scopeTransform = scopeTransform.scaledBy(x: CGFloat(scopeScale), y: CGFloat(scopeScale))

        let scopeImage = cachedRawImage.transformed(by: scopeTransform)
        
        self.imageProcessingModel.calculateExportSize(for: rawUrl)
		

        DispatchQueue.main.async {

            self.imageProcessingModel.scopeImage = scopeImage
            self.imageProcessingModel.imageToMask = cachedRawImage

			

        }
//		rawImage.hasBeenProcessed = true
		
        // Save updated RawImage back to dataModel.rawImages
        if let index = dataModel.rawImages.firstIndex(where: { $0.id == rawImage.id }) {
            dataModel.rawImages[index] = rawImage
//            print("✅ Updated rawImage in dataModel.rawImages for \(rawImage.rawUrl?.lastPathComponent ?? "unknown file")")
        }

        return cachedRawImage
    }
	

    
    // MARK: - File Extensions
    
    
    func isRawFile(fileExtension: String) -> Bool {
        let rawExtensions = ["cr3", "raf", "dng", "nef", "arw", "cr2", "orf", "srw", "3fr", "pef", "exr", "fff"]
        return rawExtensions.contains(fileExtension.lowercased())
    }

    
    
    // MARK: - SCALING
	
    var inputFullWidth: Int = 0
    
    var inputFullHeight: Int = 0
    
    var longEdgeSize: Int = 0
    
    var shortEdgeSize: Int = 0
    

   
    
    var isCanon: Bool = false
    
    var isGFX100s: Bool = false
    
    var isNikon: Bool = false
    
    
    // MARK: - RAW SCALE
    
    var rawExtentX: Int = 0
    
    var rawExtentY: Int = 0
    
    var rawScale: Float = 0.25

    
    func calculateRawScale(for rawImage: inout RawImage) {
        guard let extentX = rawImage.rawExtentX, let extentY = rawImage.rawExtentY, extentX > 0, extentY > 0 else {
            print("RAW image dimensions are not set. Cannot calculate rawScale.")
            rawImage.rawScale = 1.0
            return
        }

        guard let activeScreen = NSScreen.main else {
            print("Unable to determine the active screen. Cannot calculate rawScale.")
            rawImage.rawScale = 1.0
            return
        }

        let scaleFactor = activeScreen.backingScaleFactor
        let screenWidth = Int(activeScreen.frame.width * scaleFactor)
        let screenHeight = Int(activeScreen.frame.height * scaleFactor)

        print("Active screen resolution: \(screenWidth)x\(screenHeight) (scaleFactor: \(scaleFactor))")

        // Calculate scale factor
        let widthScale = Float(screenWidth) / Float(extentX)
        let heightScale = Float(screenHeight) / Float(extentY)
        rawImage.rawScale = min(widthScale, heightScale)

        print("Updated rawScale: \(rawImage.rawScale ?? 1.0) (based on RAW dimensions \(extentX)x\(extentY) and screen \(screenWidth)x\(screenHeight))")
    }


	
	func loadFullResolutionImage (from url: URL) -> CIImage? {
		
		guard let fullScaleImageFilter = CIRAWFilter(imageURL: url) else {
			print("Failed to create CIRAWFilter for generating full-scale image.")
			return nil
		}
		
		// Configure the filter
//		fullScaleImageFilter.baselineExposure = 0.0
		fullScaleImageFilter.shadowBias = 0.0
		fullScaleImageFilter.boostAmount = 0.0
		fullScaleImageFilter.localToneMapAmount = 0.0
		fullScaleImageFilter.isGamutMappingEnabled = false
		fullScaleImageFilter.extendedDynamicRangeAmount = 0.0
		fullScaleImageFilter.scaleFactor = 1.0
		fullScaleImageFilter.boostShadowAmount = 0.0
		fullScaleImageFilter.contrastAmount = 0.0
		fullScaleImageFilter.detailAmount = 0.0
		fullScaleImageFilter.exposure = 0.0
		fullScaleImageFilter.sharpnessAmount = 0.0
		
		
		guard let fullScaleImage = fullScaleImageFilter.outputImage else {
			print("Failed to generate image from RAW file.")
			return nil
		}

		
		return fullScaleImage
	}
	

	
	// MARK: - Extract Camera Info
	
	func extractCameraInfo(from url: URL) -> (isCanon: Bool, isGFX100s: Bool, isNikon: Bool, iso: String, fStop: String, shutterSpeed: String, cameraModel: String) {
		
		var isCanon = false
		var isGFX100s = false
		var isNikon = false
		var iso: String = "Null"
		var fStop: String = "Null"
		var shutterSpeed: String = "Null"
		var cameraModel: String = "Null"

		// Create a CGImageSource from the image URL
		guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
			print("Failed to create image source.")
			return (isCanon, isGFX100s, isNikon, iso, fStop, shutterSpeed, cameraModel)
		}

		// Get the metadata dictionary from the image source
		if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
			
			// Extract EXIF data (ISO, f-stop, shutter speed)
			if let exifData = imageProperties["{Exif}"] as? [String: Any] {
				
				// Extract ISO (Check for both "ISO" and "ISOSpeedRatings")
				if let isoValue = exifData["ISOSpeed"] as? Int {
					iso = "\(isoValue)"
				} else if let isoSpeed = exifData["ISOSpeedRatings"] as? [Int], let firstISO = isoSpeed.first {
					iso = "\(firstISO)"
				}
				
				// Extract f-stop (Aperture)
				if let aperture = exifData["FNumber"] as? Double {
					fStop = "f\(aperture)"
				}
				
				// Extract shutter speed (Convert from exposure time)
				if let exposureTime = exifData["ExposureTime"] as? Double {
					let shutterSpeedValue = Int(1.0 / exposureTime)
					shutterSpeed = shutterSpeedValue > 0 ? "1/\(shutterSpeedValue)s" : "\(exposureTime)s"
				}
			}

			// Extract Camera Model (Ignore Make)
			if let tiffData = imageProperties["{TIFF}"] as? [String: Any] {
				if let model = tiffData["Model"] as? String {
					cameraModel = model
					let lowercasedModel = model.lowercased()
					isGFX100s = lowercasedModel == "gfx100s" ||
								lowercasedModel == "gfx100" ||
								lowercasedModel == "hasselblad x1d"
					
					isCanon = lowercasedModel.contains("canon")
					isNikon = lowercasedModel.contains("nikon")
				}
			}
		}

		return (isCanon, isGFX100s, isNikon, iso, fStop, shutterSpeed, cameraModel)
	}
	
	// Pick temp and tint
	
	public class TempAndTintFilter: CIFilter {
		private var kernel: CIColorKernel?
		var inputImage: CIImage?
		var x: Float = 0.0
		var y: Float = 0.0
		
		override init() {
			super.init()
			loadKernel()
		}
		
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		private func loadKernel() {
			let frameworkBundle = Bundle(for: type(of: self))
			guard let url = frameworkBundle.url(forResource: "ScopeKernels", withExtension: "ci.metallib") else {
				fatalError("Failed to locate the Metal library file in the framework bundle.")
			}
			
			do {
				let data = try Data(contentsOf: url)
				kernel = try CIColorKernel(functionName: "calculateTempAndTintInit", fromMetalLibraryData: data)
			} catch {
				fatalError("Failed to load the Metal kernel: \(error)")
			}
		}
		
		public override var outputImage: CIImage? {
			guard let input = inputImage, let kernel = kernel else { return nil }
			
			let roiCallback: CIKernelROICallback = { index, rect in rect }
			
			return kernel.apply(extent: input.extent, roiCallback: roiCallback, arguments: [input, x, y])
		}
	}
	
	func extractFloat2Value(from image: CIImage, context: CIContext) -> (Float, Float)? {
		let width = 1
		let height = 1

		// Create a 32-bit float **RGB** pixel buffer (No Alpha)
		var pixelBuffer: CVPixelBuffer?
		let attrs = [
			kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_128RGBAFloat, // Use RGBA since RGB isn't available
			kCVPixelBufferWidthKey: width,
			kCVPixelBufferHeightKey: height
		] as CFDictionary

		let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
										 kCVPixelFormatType_128RGBAFloat,
										 attrs,
										 &pixelBuffer)

		guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else {
			print("Error: Could not create CVPixelBuffer")
			return nil
		}

		// Render CIImage into CVPixelBuffer without Alpha
		context.render(image, to: pixelBuffer, bounds: image.extent, colorSpace: nil)

		// Lock the buffer for reading
		CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

		guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
			print("Error: Could not get base address")
			CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
			return nil
		}

		// Read the float3 (RGB) data
		let floatPointer = baseAddress.assumingMemoryBound(to: Float.self)

		// Debug: Print raw pixel values
		print("Raw Pixel Buffer Data: R=\(floatPointer[0]), G=\(floatPointer[1]), B=\(floatPointer[2])")

		let temp = floatPointer[0]   // Red channel = Temp
		let tint = floatPointer[1]   // Green channel = Tint
		
		// Unlock buffer
		CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
		return (temp, tint)
	}
	
	
}
