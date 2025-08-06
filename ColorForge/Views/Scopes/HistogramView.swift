//
//  HistogramView.swift
//  ColorForge
//
//  Created by Ben Quinton on 04/08/2025.
//

import SwiftUI
import Foundation
import SwiftUI
import Charts

struct HistogramChartPoint: Identifiable {
    let id = UUID()
    let pixelValue: Int
    let frequency: Float
    let channel: String
}

struct HistogramView: View {
    @EnvironmentObject var histogramModel: HistogramModel
    @EnvironmentObject var viewModel: ImageViewModel
    @State private var isCollapsed = false
    
    
    var data: [HistogramChartPoint] {
        // Combine all channels to find the global max
        let allValues = histogramModel.red + histogramModel.green + histogramModel.blue + histogramModel.luminance
        let maxValue = allValues.map { $0.value }.max() ?? 1

        var points: [HistogramChartPoint] = []

        points += histogramModel.red.map {
            HistogramChartPoint(pixelValue: $0.id, frequency: Float($0.value) / Float(maxValue), channel: "Red")
        }
        points += histogramModel.green.map {
            HistogramChartPoint(pixelValue: $0.id, frequency: Float($0.value) / Float(maxValue), channel: "Green")
        }
        points += histogramModel.blue.map {
            HistogramChartPoint(pixelValue: $0.id, frequency: Float($0.value) / Float(maxValue), channel: "Blue")
        }
        points += histogramModel.luminance.map {
            HistogramChartPoint(pixelValue: $0.id, frequency: Float($0.value) / Float(maxValue), channel: "Luminance")
        }

        return points
    }
    
    var body: some View {
        CollapsibleSectionViewNoReset(
            title: "Histogram:",
            isCollapsed: $isCollapsed,
            content: {
                // MARK: - Histogram Overlay
                VStack(spacing: 10) {

                    if !data.isEmpty {
                        Chart(data) {
                            LineMark(
                                x: .value("Pixel Value", $0.pixelValue),
                                y: .value("Frequency", $0.frequency)
                            )
                            .foregroundStyle(by: .value("Channel", $0.channel)) // Group and style lines by channel
                            .interpolationMethod(.catmullRom) // Adds smoothing
                            .lineStyle(StrokeStyle(lineWidth: 1))
                        }
                        .chartForegroundStyleScale([
                            "Luminance": Color("SideBarText"),
                            "Red": Color.red,
                            "Green": Color.green,
                            "Blue": Color.blue
                        ])
                        .chartXScale(domain: 0...256)
                        .chartXAxis {
                            AxisMarks(preset: .aligned, values: [0, 64, 128, 192, 255]) // Custom X-axis
                        }
                        .chartPlotStyle { plotArea in
                            plotArea
                                .background(Color("MenuAccent").opacity(0.5))
                                .border(Color("MenuAccent"), width: 2)
                        }
                        .chartYScale(domain: 0...1.2)
                        .chartYAxis(.hidden)
                        .chartLegend(.hidden)
                        .frame(width: 250, height: 100)
                        .padding(5)
                    } else {
                        Text("Histogram not available")
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        )
    }
}


