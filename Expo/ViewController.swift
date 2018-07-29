//
//  ViewController.swift
//  Expo
//
//  Created by Daniel Burke on 7/28/18.
//  Copyright © 2018 Daniel Burke. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    // MARK: Properties
    let mapView = MKMapView()
    
    lazy var searchContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 5
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: -5)
        
        panGesture.addTarget(self, action: #selector(panGesture(recognizer:)))
        view.addGestureRecognizer(panGesture)
        
        return view
    }()
    
    let searchBar: UIView = {
        let view = UIView()
        return view
    }()
    
    let underline: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
        return layer
    }()
    
    let handleBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        view.layer.cornerRadius = 3
        return view
    }()
    
    lazy var searchField: Field = {
        let field = Field()
        field.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        field.placeholder = "Search"
        field.layer.cornerRadius = 10
        field.delegate = self
        return field
    }()
    
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.isScrollEnabled = false
        view.rowHeight = 80
        view.separatorInset = .zero
        view.register(LocationCell.self, forCellReuseIdentifier: "cell")
        
        view.delegate = self
        view.dataSource = self
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    var startingOffset: CGFloat = 0
    let topPadding: CGFloat = 64
    var heightConstraint: NSLayoutConstraint?
    lazy var maxOffset = (view.frame.height*0.7)-topPadding
    
    lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = self
        return gesture
    }()
    
    // MARK: Lifecylce
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        view.addSubview(mapView)
        searchBar.addSubview(handleBar)
        searchBar.addSubview(searchField)
        searchBar.layer.addSublayer(underline)
        searchContainer.addSubview(searchBar)
        searchContainer.addSubview(tableView)
        view.addSubview(searchContainer)
        
        installConstraints()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let size = searchBar.frame.size
        underline.frame = CGRect(x: 0, y: size.height-1, width: size.width, height: 1)
    }
}

extension ViewController {
    @objc func panGesture(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        
        switch recognizer.state {
            
        // ** Tracking starting offset
        case .began: startingOffset = heightConstraint?.constant ?? 0
            
        // ** Toggle panGesture and tableView to properly switch between gestures
        case .changed:
            let offset = startingOffset - translation.y
            var minOffset: CGFloat = 0
            
            mapView.alpha = 1 - (0.5 * (offset / maxOffset))
            
            // This adds elasticity
            if offset < 0 {
                minOffset = -(0 - offset)/3
            }
            
            // ** Track bottom sheet with pan gesture by finding the diff
            // be tween translation and starting offset, then constraint
            // this value to be between our top margin and min height
            let currentOffset = min(maxOffset, max(minOffset, offset))
            heightConstraint?.constant = currentOffset
            
            // ** `offset` == 0 means the sheet is minimized
            // `offset` == `maxOffset` means the sheet is open
            if currentOffset == 0 {
                tableView.contentOffset = .zero
                tableView.isScrollEnabled = false
            } else if currentOffset == maxOffset {
                panGesture.isEnabled = false
                panGesture.isEnabled = true
                tableView.isScrollEnabled = true
            }
            
        case .ended, .cancelled:
            guard let offset = heightConstraint?.constant else { return }
            
            // ** Handle last position - if nearer to the top finish out the
            // animation to the top, and vice versa
            var finalOffset: CGFloat = offset > maxOffset/2 ? maxOffset : 0
            let velocity = recognizer.velocity(in: view).y
            
            // ** Toggle tableView scrollability
            // Handle "flick" action using `velocity`
            if velocity < -100 {
                finalOffset = maxOffset
                tableView.isScrollEnabled = true
            } else if offset > maxOffset/2 && velocity > 200 {
                finalOffset = 0
                tableView.isScrollEnabled = false
            } else {
                tableView.isScrollEnabled = offset > maxOffset/2
            }
            
            // Dismiss keyboard if dismissing sheet
            if finalOffset == 0 {
                _ = searchField.resignFirstResponder()
            }
            
            // ** Animate to top or bottom docking position when gesture ends
            // or is cancelled
            heightConstraint?.constant = finalOffset
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseOut, .allowUserInteraction], animations: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.view.layoutIfNeeded()
                strongSelf.mapView.alpha = 1 - (0.5 * (finalOffset / strongSelf.maxOffset))

            }, completion: nil)
            
        default: ()
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let offset = heightConstraint?.constant else { return }
        
        // ** Disable panning if scrollView isn't at the top
        panGesture.isEnabled = tableView.contentOffset.y <= 0 || offset == 0
        
        // ** Don't scroll if bottom sheet is panning down
        if scrollView.contentOffset.y < 0 {
            scrollView.isScrollEnabled = false
            panGesture.isEnabled = true
        }
    }
    
    // Arbitrary count, not important
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    // Arbitrary styling, not important
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.selectionStyle = .none
        return cell
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    // ** Handle both the scrollView/tableView pan gesture and your custom pan gesture
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


extension ViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // ** Animate to top or bottom docking position when gesture ends
        // or is cancelled
        heightConstraint?.constant = maxOffset
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: [.curveEaseOut, .allowUserInteraction], animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.view.layoutIfNeeded()
            strongSelf.mapView.alpha = 0.5
        }, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ViewController {
    func installConstraints() {
        // Add constraints using Anchors
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        mapView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        searchContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        heightConstraint = searchContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3)
        heightConstraint?.isActive = true
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 0).isActive = true
        searchBar.topAnchor.constraint(equalTo: searchContainer.topAnchor, constant: 0).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: 0).isActive = true
        searchBar.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        handleBar.topAnchor.constraint(equalTo: searchBar.topAnchor, constant: 8).isActive = true
        handleBar.centerXAnchor.constraint(equalTo: searchBar.centerXAnchor).isActive = true
        handleBar.widthAnchor.constraint(equalToConstant: 30).isActive = true
        handleBar.heightAnchor.constraint(equalToConstant: 6).isActive = true
        
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: 16).isActive = true
        searchField.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: -16).isActive = true
        searchField.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 8).isActive = true
        searchField.bottomAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: -12).isActive = true
        
        // Add constraints using Anchors
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 0).isActive = true
        tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 0).isActive = true
        tableView.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: 0).isActive = true
        tableView.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 0).isActive = true
        
        view.layoutIfNeeded()
    }
}
