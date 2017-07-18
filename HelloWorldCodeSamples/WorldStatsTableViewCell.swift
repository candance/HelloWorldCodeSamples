//
//  WorldStatsTableViewCell.swift
//  HelloWorld
//
//  Created by Candance Smith on 8/15/16.
//  Copyright © 2016 candance. All rights reserved.
//

import UIKit

class WorldStatsTableViewCell: UITableViewCell {
    
    // MARK: - Outlets and Variables

    @IBOutlet weak var continentNameLabel: UILabel?
    @IBOutlet weak var percentVisitedLabel: UILabel?
    @IBOutlet weak var progressBarBorderView: UIView?
    @IBOutlet weak var progressBarFill: UIView?
    
    @IBOutlet weak var progressBarFillTrailing: NSLayoutConstraint?
    
    // MARK: - Set Up View
    
    override func awakeFromNib() {
        super.awakeFromNib()
        progressBarBorderView?.layer.backgroundColor = UIColor.lightGray.cgColor
        progressBarBorderView?.layer.cornerRadius = 4.0
    }
    
    func setUpCell(_ continentName: String, percentVisited: UInt, barColor: UIColor) {
        continentNameLabel?.text = continentName
        continentNameLabel?.font = StyleManager.labelFont(continentNameLabel)
        continentNameLabel?.textColor = Style.darkGrayColor
        
        percentVisitedLabel?.text = "\(percentVisited)%"
        percentVisitedLabel?.font = StyleManager.labelFont(percentVisitedLabel)
        percentVisitedLabel?.textColor = Style.darkGrayColor
        
        if let progressBarBorderWidth = progressBarBorderView?.frame.size.width {
            progressBarFillTrailing?.constant = progressBarBorderWidth - CGFloat(percentVisited) * 0.01 * progressBarBorderWidth
        }
        
        progressBarFill?.layer.cornerRadius = 4.0
        progressBarFill?.backgroundColor = barColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        continentNameLabel?.text = nil
        percentVisitedLabel?.text = nil
    }
}
