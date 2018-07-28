//
//  ViewController.swift
//  Expo
//
//  Created by Daniel Burke on 7/28/18.
//  Copyright © 2018 Daniel Burke. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = .lightGray
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        return view
    }()
    
    var startingOffset: CGFloat = 0
    let topPadding: CGFloat = 64
    var heightConstraint: NSLayoutConstraint?
    let panGesture = UIPanGestureRecognizer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
        panGesture.addTarget(self, action: #selector(panGesture(recognizer:)))
        tableView.addGestureRecognizer(panGesture)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)
        heightConstraint?.isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    }
}

extension ViewController {
    @objc func panGesture(recognizer: UIPanGestureRecognizer) {
        let maxOffset = (view.frame.height*0.5)-topPadding
        let translation = recognizer.translation(in: view)
        
        switch recognizer.state {
        case .began: startingOffset = heightConstraint?.constant ?? 0
        case .changed:
            let offset = startingOffset - translation.y
            heightConstraint?.constant = min(maxOffset, max(0, offset))
        case .ended, .cancelled:
            guard let offset = heightConstraint?.constant else { return }

            let finalOffset = offset > maxOffset/2 ? maxOffset : 0
            heightConstraint?.constant = finalOffset

            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .curveEaseInOut, animations: { [weak self] in

                guard let strongSelf = self else { return }
                strongSelf.view.layoutIfNeeded()

            }, completion: nil)
            
        default: ()
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    }
}

