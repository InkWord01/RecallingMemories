//
//  RecallingMemoriesWidgetBundle.swift
//  RecallingMemoriesWidget
//
//  Widget Extension 入口 — 注册所有 Widget
//

import WidgetKit
import SwiftUI

@main
struct RecallingMemoriesWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickRecordWidget()
        OnThisDayWidget()
    }
}
