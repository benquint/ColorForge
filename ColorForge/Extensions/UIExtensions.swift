//
//  UIExtensions.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import Foundation


public var wholeNumber: NumberFormatter {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.minimumFractionDigits = 0
	formatter.maximumFractionDigits = 0
	return formatter
}

// Two Decimals
public var twoDecimal: NumberFormatter {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.minimumFractionDigits = 2
	formatter.maximumFractionDigits = 2
	return formatter
}





