//
//  WMCProgressOverlay.swift
//  WMC - Private Functions
//
//  Created by Wai Man Chan on 3/23/17.
//  Copyright © 2017 Wai Man Chan. All rights reserved.
//

import UIKit

struct WMCactivityIndicatorOverlay {
    let rootView: UIView
    let label: UILabel
    let activityIndicator: UIActivityIndicatorView
    func setHidden(_ state: Bool) {
        rootView.isHidden = state
        if state { activityIndicator.stopAnimating() }
        else     { activityIndicator.startAnimating()}
    }
}

func createActivityIndicatorOverlay(superView: UIView) -> WMCactivityIndicatorOverlay {
    let view = UIView()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 5
    view.clipsToBounds = true
    
    superView.addSubview(view)
    
    //Bound the super view
    let relationCenX = NSLayoutConstraint.init(item: view, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1, constant: 0)
    let relationCenY = NSLayoutConstraint.init(item: view, attribute: .centerY, relatedBy: .equal, toItem: superView, attribute: .centerY, multiplier: 1, constant: 0)
    let sizeX = NSLayoutConstraint.init(item: view, attribute: .width, relatedBy: .equal, toItem: superView, attribute: .width, multiplier: 0.7, constant: 0)
    let sizeY = NSLayoutConstraint.init(item: view, attribute: .height, relatedBy: .equal, toItem: superView, attribute: .height, multiplier: 0.2, constant: 0)
    superView.addConstraints([relationCenX, relationCenY, sizeX, sizeY])
    
    
    //Add effect
    let effect = UIBlurEffect.init(style: UIBlurEffectStyle.dark)
    let blurView = UIVisualEffectView.init(effect: effect)
    blurView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(blurView)
    
    let blurSizeX = NSLayoutConstraint.init(item: view, attribute: .width, relatedBy: .equal, toItem: blurView, attribute: .width, multiplier: 1, constant: 0)
    let blurSizeY = NSLayoutConstraint.init(item: view, attribute: .height, relatedBy: .equal, toItem: blurView, attribute: .height, multiplier: 1, constant: 0)
    let blurPosX = NSLayoutConstraint.init(item: view, attribute: .centerX, relatedBy: .equal, toItem: blurView, attribute: .centerX, multiplier: 1, constant: 0)
    let blurPosY = NSLayoutConstraint.init(item: view, attribute: .centerY, relatedBy: .equal, toItem: blurView, attribute: .centerY, multiplier: 1, constant: 0)
    view.addConstraints([blurSizeX, blurSizeY, blurPosX, blurPosY])
    
    //Vibracy
    let virbEffect = UIVibrancyEffect.init(blurEffect: effect)
    let virbView = UIVisualEffectView.init(effect: virbEffect)
    virbView.translatesAutoresizingMaskIntoConstraints = false
    blurView.contentView.addSubview(virbView)
    
    let vibrancySizeX = NSLayoutConstraint.init(item: virbView, attribute: .width, relatedBy: .equal, toItem: blurView, attribute: .width, multiplier: 1, constant: 0)
    let vibrancySizeY = NSLayoutConstraint.init(item: virbView, attribute: .height, relatedBy: .equal, toItem: blurView, attribute: .height, multiplier: 1, constant: 0)
    let vibrancyPosX = NSLayoutConstraint.init(item: virbView, attribute: .centerX, relatedBy: .equal, toItem: blurView, attribute: .centerX, multiplier: 1, constant: 0)
    let vibrancyPosY = NSLayoutConstraint.init(item: virbView, attribute: .centerY, relatedBy: .equal, toItem: blurView, attribute: .centerY, multiplier: 1, constant: 0)
    view.addConstraints([vibrancySizeX, vibrancySizeY, vibrancyPosX, vibrancyPosY])
    virbView.contentView.addSubview(indicator)
    
    
    //Bound the indicator position
    let indictRelationCenX = NSLayoutConstraint.init(item: indicator, attribute: .centerX, relatedBy: .equal, toItem: virbView.contentView, attribute: .centerX, multiplier: 1, constant: 0)
    let indictRelationCenY = NSLayoutConstraint.init(item: indicator, attribute: .bottom, relatedBy: .equal, toItem: virbView.contentView, attribute: .bottom, multiplier: 1, constant: -20)
    
    //Create text view
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    let labelHeigh = NSLayoutConstraint.init(item: label, attribute: .width, relatedBy: .equal, toItem: virbView.contentView, attribute: .width, multiplier: 1, constant: -16)
    let labelPosX = NSLayoutConstraint.init(item: label, attribute: .top, relatedBy: .equal, toItem: virbView.contentView, attribute: .top, multiplier: 1, constant: 0)
    let labelPosY = NSLayoutConstraint.init(item: label, attribute: .left, relatedBy: .equal, toItem: virbView.contentView, attribute: .left, multiplier: 1, constant: 8)
    let labelWidth = NSLayoutConstraint.init(item: label, attribute: .bottom, relatedBy: .equal, toItem: indicator, attribute: .top, multiplier: 1, constant: -8)
    virbView.contentView.addSubview(label)
    virbView.contentView.addConstraints([indictRelationCenX, indictRelationCenY, labelPosX, labelPosY, labelHeigh, labelWidth])
    label.text = "Testing"
    label.textAlignment = .center
    
    superView.layoutIfNeeded()
    view.layoutIfNeeded()
    blurView.layoutIfNeeded()
    virbView.layoutIfNeeded()
    indicator.layoutIfNeeded()
    label.layoutIfNeeded()
    
    return WMCactivityIndicatorOverlay.init(rootView: view, label: label, activityIndicator: indicator)
}
