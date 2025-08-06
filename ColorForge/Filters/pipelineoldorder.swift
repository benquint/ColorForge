    
   func buildPipeline(
       for item: ImageItem,
       isInit: Bool,
       isExport: Bool,
       isLut: Bool,
       maskingActive: Bool,
       selectedMask: ImageItem.LinearGradientMask?
   ) -> [FilterNode] {
       
       var pipeline: [FilterNode] = []

       for nodeName in pipelineOrder {
           switch nodeName {

				// MASK
           case "TempAndTintNode":
               let node = TempAndTintNode(
                   isMask: false,
                   targetTemp: item.initTemp,
                   targetTint: item.initTint,
                   sourceTemp: item.temp,
                   sourceTint: item.tint,
                   convertToNeg: item.convertToNeg
               )
               pipeline.append(node)

				// MASK
           case "RawExposureNode":
               let node = RawExposureNode(
                   isMask: false,
                   exposure: isInit ? 2.0 : item.exposure,
                   convertToNeg: item.convertToNeg,
                   bwMode: item.bwMode,
                   isLut: isLut
               )
               pipeline.append(node)
               if maskingActive,
                  selectedMask != nil,
                  MaskableNodeTypes.contains("RawExposureNode"),
                  let masked = duplicateNodeWithMask(node, mask: selectedMask!) {
                   pipeline.append(masked)
               }
				
				// MASK
           case "RawContrastNode":
               let node = RawContrastNode(isMask: false, contrast: item.contrast)
               pipeline.append(node)
               if maskingActive,
                  selectedMask != nil,
                  MaskableNodeTypes.contains("RawContrastNode"),
                  let masked = duplicateNodeWithMask(node, mask: selectedMask!) {
                   pipeline.append(masked)
               }

				// MASK
           case "GlobalSaturationNode":
               let node = GlobalSaturationNode(isMask: false, saturation: item.saturation)
               pipeline.append(node)
               if maskingActive,
                  selectedMask != nil,
                  MaskableNodeTypes.contains("GlobalSaturationNode"),
                  let masked = duplicateNodeWithMask(node, mask: selectedMask!) {
                   pipeline.append(masked)
               }

				// MASK
           case "HDRNode":
               let node = HDRNode(
                   isMask: false,
                   hdrWhite: isInit ? 40 : item.hdrWhite,
                   hdrHighlight: item.hdrHighlight,
                   hdrShadow: item.hdrShadow,
                   hdrBlack: item.hdrBlack
               )
               pipeline.append(node)
               if maskingActive,
                  selectedMask != nil,
                  MaskableNodeTypes.contains("HDRNode"),
                  let masked = duplicateNodeWithMask(node, mask: selectedMask!) {
                   pipeline.append(masked)
               }

           case "PreviewHueRangeNode":
               pipeline.append(PreviewHueRangeNode(
                   previewRed: isInit ? true : item.previewRed,
                   previewGreen: item.previewGreen,
                   previewBlue: item.previewBlue,
                   previewCyan: item.previewCyan,
                   previewMagenta: item.previewMagenta,
                   previewYellow: item.previewYellow
               ))

				// MASK
           case "HueSaturationDensityNode":
               let node = HueSaturationDensityNode(
                   isMask: false,
                   redHue: isInit ? 20.0 : item.redHue,
                   redSat: item.redSat,
                   redDen: item.redDen,
                   greenHue: item.greenHue,
                   greenSat: item.greenSat,
                   greenDen: item.greenDen,
                   blueHue: item.blueHue,
                   blueSat: item.blueSat,
                   blueDen: item.blueDen,
                   cyanHue: item.cyanHue,
                   cyanSat: item.cyanSat,
                   cyanDen: item.cyanDen,
                   magentaHue: item.magentaHue,
                   magentaSat: item.magentaSat,
                   magentaDen: item.magentaDen,
                   yellowHue: item.yellowHue,
                   yellowSat: item.yellowSat,
                   yellowDen: item.yellowDen
               )
               pipeline.append(node)


				
           case "GrainNode":
               pipeline.append(GrainV3Node(
                   amount: item.grainAmount,
                   applyGrain: item.applyGrain,
                   applyMTF: item.applyMTF,
                   format: item.selectedGateWidth,
                   exportMode: isExport
               ))

           case "MTFCurveNode":
               let nativeLongEdge = max(item.nativeWidth, item.nativeHeight)
               pipeline.append(MTFCurveNode(
                   applyMTF: isInit ? true : item.applyMTF,
                   mtfAmount: item.mtfBlend,
                   format: item.selectedGateWidth,
                   applyGrain: item.applyGrain,
                   exportMode: isExport,
                   nativeLongEdge: nativeLongEdge
               ))

           case "FilmStockNode":
               pipeline.append(FilmStockNode(
                   stockChoice: item.stockChoice,
                   convertToNeg: item.convertToNeg
               ))

           case "OffsetNode":
               let node = OffsetNode(
                   applyScanMode: item.applyScanMode,
                   offsetRGB: item.offsetRGB,
                   offsetRed: item.offsetRed,
                   offsetGreen: item.offsetGreen,
                   offsetBlue: item.offsetBlue
               )
               pipeline.append(node)


				
           case "Kodak2383Node":
               pipeline.append(Kodak2383Node(
                   blend: item.lutBlend,
                   applyScanMode: item.applyScanMode,
                   applyPFE: item.applyPFE
               ))

				
           case "ScanContrastNode":
               let node = ScanContrastNode(
                   applyScanMode: item.applyScanMode,
                   scanContrast: item.scanContrast
               )
               pipeline.append(node)


				// MASK
           case "PrintHalationNode":
               let node = PrintHalationNode(
                   isMask: false,
                   radiusMultiplier: item.radiusMultiplier,
                   radiusExponent: item.radiusExponent,
                   opacityMultiplier: item.opacityMultiplier,
                   applyPrintHalation: item.applyPrintHalation
               )
               pipeline.append(node)

				
				
			case "PaperSoftenNode":
				let node = PaperSoftenNode(applyPrintMode: item.applyPrintMode)
				pipeline.append(node)
				
				// MASK
			case "EnlargerV2Node":
				let node = EnlargerV2Node(
					isMask: isMask,
					applyPrintMode: item.applyPrintMode,
					convertToNeg: item.convertToNeg,
					evSeconds: item.enlargerExp,
					fstop: item.enlargerFStop,
					cyan: item.cyan,
					magenta: item.magenta,
					yellow: item.yellow,
					bwMode: item.bwMode,
					useLegacy: item.useLegacy)
				pipeline.append(node)
				
				// MASK
			case "LegacyEnlargerNode":
				let node = LegacyEnlargerNode(
					isMask: isMask,
					applyPrintMode: item.applyPrintMode,
					convertToNeg: item.convertToNeg,
					evSeconds: item.legacyExposure,
					cyan: item.legacyCyan,
					magenta: item.legacyMagenta,
					yellow: item.legacyYellow,
					bwMode: item.bwMode,
					stockChoice: item.stockChoice,
					useLegacy: item.useLegacy)
				pipeline.append(node)

			

			case "LegacyPrintCurveAndGamutNode":
				let node = LegacyPrintCurveAndGamutNode(
					bwMode: item.bwMode,
					applyPrintMode: item.applyPrintMode,
					stockChoice: item.stockChoice,
					useLegacy: item.useLegacy)
				pipeline.append(node)
				
			
				
			case "PrintGamutNode":
				let node = PrintGamutNode(
					applyPrintMode: item.applyPrintMode,
					bwMode: item.bwMode,
					useLegacy: item.useLegacy)
				
			
				// MASK
			case "BlackAndWhiteEnlargerNode":
				let node = BlackAndWhiteEnlargerNode(
					applyPrintMode: item.applyPrintMode,
					isMask: isMask,
					evSeconds: item.enlargerExp,
					fstop: item.enlargerFStop,
					magenta: item.magenta,
					bwMode: item.bwMode,
					useLegacy: item.useLegacy)


           case "DecodeNegativeNode":
               pipeline.append(DecodeNegativeNode(
                   convertToNeg: isInit ? true : item.convertToNeg,
                   applyScanMode: item.applyScanMode,
                   stockChoice: item.stockChoice
               ))

           case "ApplyAdobeCameraRawCurveNode":
               pipeline.append(ApplyAdobeCameraRawCurveNode(
                   convertToNeg: item.convertToNeg
               ))

           default:
               print("Unknown node: \(nodeName)")
           }
       }

       return pipeline
   }
