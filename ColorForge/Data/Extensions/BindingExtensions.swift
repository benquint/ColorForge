//
//  BindingExtensions.swift
//  ColorForge
//
//  Created by admin on 01/07/2025.
//

import Foundation
import SwiftUI
import AppKit
import CoreImage
import CoreGraphics


extension DataModel {
	
	func bindingToItem<T: Equatable>(
		keyPath: WritableKeyPath<ImageItem, T>,
		defaultValue: T
	) -> Binding<T> {
		let viewModel = ImageViewModel.shared
		let thumbViewModel = ThumbnailViewModel.shared
		let modelId = viewModel.currentImgID
		let selectedIDs = thumbViewModel.selectedIDs

		let key = "\(modelId?.uuidString ?? "none")_\(keyPath)"

		// Clear cache if currentId changed
		if cachedBindingId != modelId {
			bindingCache.removeAll()
			cachedBindingId = modelId
		}

		// Reuse cached binding if available
		if let cached = bindingCache[key] as? Binding<T> {
			return cached
		}

		let binding = Binding<T>(
			get: {
				// Always show value for currentImgID (or first selected if current is nil)
				let id = modelId ?? selectedIDs.first
				guard let id = id,
					  let index = self.itemIndexMap[id] else {
					return defaultValue
				}
				return self.items[index][keyPath: keyPath]
			},
			set: { newValue in
				let idsToUpdate: [UUID]
				if !selectedIDs.isEmpty {
					idsToUpdate = selectedIDs
				} else if let id = modelId {
					idsToUpdate = [id]
				} else {
					return
				}

				// Update all bindings first
				for id in idsToUpdate {
					guard let idx = self.itemIndexMap[id] else { continue }
					let oldValue = self.items[idx][keyPath: keyPath]
					guard oldValue != newValue else { continue }

					self.undoManager?.registerUndo(withTarget: self) { targetSelf in
						guard let undoIndex = targetSelf.itemIndexMap[id] else { return }
						var undoItem = targetSelf.items[undoIndex]
						undoItem[keyPath: keyPath] = oldValue
						targetSelf.items[undoIndex] = undoItem

//						Task(priority: .userInitiated) {
//							await FilterPipeline.shared.applyPipelineV2(id, self)
//						}
                        FilterPipeline.shared.applyPipelineV2Sync(id, self)
					}

					self.undoManager?.setActionName("Adjust Image Setting")

					var updated = self.items[idx]
					updated[keyPath: keyPath] = newValue
					self.items[idx] = updated
					self.objectWillChange.send()
					
				}

				// Run all pipelines concurrently
				Task(priority: .userInitiated) {
					await withTaskGroup(of: Void.self) { group in
						for id in idsToUpdate {
							group.addTask {
//								await FilterPipeline.shared.applyPipelineV2(id, self)
                                FilterPipeline.shared.applyPipelineV2Sync(id, self)
							}
						}
					}
				}
			}
		)

		bindingCache[key] = binding
		return binding
	}
	
//	func bindingToItem<T: Equatable>(
//		keyPath: WritableKeyPath<ImageItem, T>,
//		defaultValue: T
//	) -> Binding<T> {
//		let viewModel = ImageViewModel.shared
//		let modelId = viewModel.currentImgID
//		
//		let key = "\(modelId?.uuidString ?? "none")_\(keyPath)"
//        
//		
//        
//		// Clear cache if currentId changed
//		if cachedBindingId != modelId {
//			bindingCache.removeAll()
//			cachedBindingId = modelId
//		}
//
//		// Reuse cached binding if available
//		if let cached = bindingCache[key] as? Binding<T> {
//			return cached
//		}
//
//		// Create and cache the binding
//		let binding = Binding<T>(
//			get: {
//				guard let id = modelId,
//					  let index = self.itemIndexMap[id] else {
//					return defaultValue
//				}
//				return self.items[index][keyPath: keyPath]
//			},
//			set: { newValue in
//				guard let id = modelId,
//					  let index = self.itemIndexMap[id] else { return }
//
//				let oldValue = self.items[index][keyPath: keyPath]
//				guard oldValue != newValue else { return }
//
//				self.undoManager?.registerUndo(withTarget: self) { targetSelf in
//					guard let undoIndex = targetSelf.itemIndexMap[id] else { return }
//					var undoItem = targetSelf.items[undoIndex]
//					undoItem[keyPath: keyPath] = oldValue
//					targetSelf.items[undoIndex] = undoItem
//                    
//					if let id = modelId {
//						Task(priority: .userInitiated) {
//							await FilterPipeline.shared.applyPipelineV2(id, self)
//						}
//					}
//				}
//				self.undoManager?.setActionName("Adjust Image Setting")
//
//				var updated = self.items[index]
//				updated[keyPath: keyPath] = newValue
//				self.items[index] = updated
//				if let id = modelId {
//					Task(priority: .userInitiated) {
//						await FilterPipeline.shared.applyPipelineV2(id, self)
//					}
//				}
//			}
//		)
//
//		bindingCache[key] = binding
//		return binding
//	}
    
    
    func bindingToMaskValue<T: Equatable>(
        maskId: UUID,
        keyPath: WritableKeyPath<MaskParameterSet, T>,
        defaultValue: T
    ) -> Binding<T> {
        
        Binding<T>(
            get: {
                let viewModel = ImageViewModel.shared
                guard
                    let id = viewModel.currentImgID,
                    let imageIndex = self.itemIndexMap[id],
                    let maskSettings = self.items[imageIndex].maskSettings.settingsByMaskID[maskId]
                else {
                    return defaultValue
                }
                
                return maskSettings[keyPath: keyPath]
            },
            set: { newValue in
                let viewModel = ImageViewModel.shared
                guard
                    let id = viewModel.currentImgID,
                    let imageIndex = self.itemIndexMap[id]
                else {
                    return
                }

                var item = self.items[imageIndex]
                var settings = item.maskSettings.settingsByMaskID[maskId] ?? MaskParameterSet()
                let oldValue = settings[keyPath: keyPath]
                guard oldValue != newValue else { return }

                settings[keyPath: keyPath] = newValue
                item.maskSettings.settingsByMaskID[maskId] = settings
                self.items[imageIndex] = item

                self.undoManager?.registerUndo(withTarget: self) { targetSelf in
                    guard let undoImageIndex = targetSelf.itemIndexMap[id] else { return }
                    var undoItem = targetSelf.items[undoImageIndex]
                    var undoSettings = undoItem.maskSettings.settingsByMaskID[maskId] ?? MaskParameterSet()
                    undoSettings[keyPath: keyPath] = oldValue
                    undoItem.maskSettings.settingsByMaskID[maskId] = undoSettings
                    targetSelf.items[undoImageIndex] = undoItem
                    
                    FilterPipeline.shared.applyPipelineV2Sync(id, targetSelf)
                }

                self.undoManager?.setActionName("Adjust Mask Setting")
                FilterPipeline.shared.applyPipelineV2Sync(id, self)
            }
        )
    }
    
    
    
    func bindingToGradientMaskValue<T: Equatable>(
        maskId: UUID,
        keyPath: WritableKeyPath<LinearGradientMask, T>,
        defaultValue: T
    ) -> Binding<T> {
        Binding<T>(
            get: {
                let viewModel = ImageViewModel.shared
                guard
                    let id = viewModel.currentImgID,
                    let imageIndex = self.itemIndexMap[id],
                    let maskIndex = self.items[imageIndex].maskSettings.linearGradients.firstIndex(where: { $0.id == maskId })
                else {
                    return defaultValue
                }
                return self.items[imageIndex].maskSettings.linearGradients[maskIndex][keyPath: keyPath]
            },
            set: { newValue in
                let viewModel = ImageViewModel.shared
                guard
                    let id = viewModel.currentImgID,
                    let imageIndex = self.itemIndexMap[id],
                    let maskIndex = self.items[imageIndex].maskSettings.linearGradients.firstIndex(where: { $0.id == maskId })
                else {
                    return
                }

                var item = self.items[imageIndex]
                var mask = item.maskSettings.linearGradients[maskIndex]
                let oldValue = mask[keyPath: keyPath]
                guard oldValue != newValue else { return }

                mask[keyPath: keyPath] = newValue
                item.maskSettings.linearGradients[maskIndex] = mask
                self.items[imageIndex] = item

                self.undoManager?.registerUndo(withTarget: self) { targetSelf in
                    guard let undoIndex = targetSelf.itemIndexMap[id] else { return }
                    var undoItem = targetSelf.items[undoIndex]
                    var undoMask = undoItem.maskSettings.linearGradients[maskIndex]
                    undoMask[keyPath: keyPath] = oldValue
                    undoItem.maskSettings.linearGradients[maskIndex] = undoMask
                    targetSelf.items[undoIndex] = undoItem
//                    Task { await FilterPipeline.shared.applyPipelineV2(id, targetSelf) }
                    FilterPipeline.shared.applyPipelineV2Sync(id, targetSelf)
                }

                self.undoManager?.setActionName("Adjust Mask")
//                Task { await FilterPipeline.shared.applyPipelineV2(id, self) }
                FilterPipeline.shared.applyPipelineV2Sync(id, self)
            }
        )
    }
    
    func bindingToRadialMaskValue<T: Equatable>(
        maskId: UUID,
        keyPath: WritableKeyPath<RadialGradientMask, T>,
        defaultValue: T
    ) -> Binding<T> {
        Binding<T>(
            get: {
                let viewModel = ImageViewModel.shared
                guard
                    let id = viewModel.currentImgID,
                    let imageIndex = self.itemIndexMap[id],
                    let maskIndex = self.items[imageIndex].maskSettings.radialGradients.firstIndex(where: { $0.id == maskId })
                else {
                    return defaultValue
                }
                return self.items[imageIndex].maskSettings.radialGradients[maskIndex][keyPath: keyPath]
            },
            set: { newValue in
                let viewModel = ImageViewModel.shared
                guard
                    let id = viewModel.currentImgID,
                    let imageIndex = self.itemIndexMap[id],
                    let maskIndex = self.items[imageIndex].maskSettings.radialGradients.firstIndex(where: { $0.id == maskId })
                else {
                    return
                }

                var item = self.items[imageIndex]
                var mask = item.maskSettings.radialGradients[maskIndex]
                let oldValue = mask[keyPath: keyPath]
                guard oldValue != newValue else { return }

                mask[keyPath: keyPath] = newValue
                item.maskSettings.radialGradients[maskIndex] = mask
                self.items[imageIndex] = item

                self.undoManager?.registerUndo(withTarget: self) { targetSelf in
                    guard let undoIndex = targetSelf.itemIndexMap[id] else { return }
                    var undoItem = targetSelf.items[undoIndex]
                    var undoMask = undoItem.maskSettings.radialGradients[maskIndex]
                    undoMask[keyPath: keyPath] = oldValue
                    undoItem.maskSettings.radialGradients[maskIndex] = undoMask
                    targetSelf.items[undoIndex] = undoItem
//                    Task { await FilterPipeline.shared.applyPipelineV2(id, targetSelf) }
                    FilterPipeline.shared.applyPipelineV2Sync(id, targetSelf)
                }

                self.undoManager?.setActionName("Adjust Mask")
//                Task { await FilterPipeline.shared.applyPipelineV2(id, self) }
                FilterPipeline.shared.applyPipelineV2Sync(id, self)
            }
        )
    }
    
//    func bindingToMaskValue<T: Equatable>(
//        maskId: UUID,
//        keyPath: WritableKeyPath<ImageItem.LinearGradientMask, T>,
//        defaultValue: T
//    ) -> Binding<T> {
//
//		
//        Binding<T>(
//            get: {
//				let viewModel = ImageViewModel.shared
//				let modelId = viewModel.currentImgID
//				
//                guard let id = modelId,
//                      let imageIndex = self.itemIndexMap[id],
//                      let maskIndex = self.items[imageIndex].maskSettings.linearGradients.firstIndex(where: { $0.id == maskId }) else {
//                    return defaultValue
//                }
//                return self.items[imageIndex].maskSettings.linearGradients[maskIndex][keyPath: keyPath]
//            },
//            set: { newValue in
//				
//				let viewModel = ImageViewModel.shared
//				let modelId = viewModel.currentImgID
//				
//                guard let id = modelId,
//                      let imageIndex = self.itemIndexMap[id],
//                      let maskIndex = self.items[imageIndex].maskSettings.linearGradients.firstIndex(where: { $0.id == maskId }) else {
//                    return
//                }
//
//                var updatedMask = self.items[imageIndex].maskSettings.linearGradients[maskIndex]
//                let oldValue = updatedMask[keyPath: keyPath]
//                guard oldValue != newValue else { return }
//
//                updatedMask[keyPath: keyPath] = newValue
//
//                var updatedItem = self.items[imageIndex]
//                updatedItem.maskSettings.linearGradients[maskIndex] = updatedMask
//                self.items[imageIndex] = updatedItem
//
//                self.undoManager?.registerUndo(withTarget: self) { targetSelf in
//                    guard let undoImageIndex = targetSelf.itemIndexMap[id] else { return }
//                    var undoItem = targetSelf.items[undoImageIndex]
//                    var undoMask = undoItem.maskSettings.linearGradients[maskIndex]
//                    undoMask[keyPath: keyPath] = oldValue
//                    undoItem.maskSettings.linearGradients[maskIndex] = undoMask
//                    targetSelf.items[undoImageIndex] = undoItem
//					if let id = modelId {
//						Task(priority: .userInitiated) {
//							await FilterPipeline.shared.applyPipelineV2(id, self)
//						}
//					}
//                }
//
//                self.undoManager?.setActionName("Adjust Mask Setting")
//				if let id = modelId {
//					Task(priority: .userInitiated) {
//						await FilterPipeline.shared.applyPipelineV2(id, self)
//					}
//				}
//            }
//        )
//    }

	
	
}

extension Binding where Value: Equatable {
    func reset(to defaultValue: Value) {
        if self.wrappedValue != defaultValue {
            self.wrappedValue = defaultValue
        }
    }
}

