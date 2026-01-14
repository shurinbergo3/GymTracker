//
//  GymTrackerWidgetBundle.swift
//  GymTrackerWidget
//
//  Created by Aleksandr Shuvalov on 1/14/26.
//

import WidgetKit
import SwiftUI

@main
struct GymTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        GymTrackerWidget()
        GymTrackerWidgetControl()
        GymTrackerWidgetLiveActivity()
    }
}
