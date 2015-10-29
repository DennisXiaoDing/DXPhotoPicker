//
//  DXPhotoBroswer.swift
//  DXPhotosPickerDemo
//
//  Created by Ding Xiao on 15/10/14.
//  Copyright © 2015年 Dennis. All rights reserved.
//

import UIKit
import Photos

@objc protocol DXPhotoBroswerDelegate: NSObjectProtocol {
    
    func sendImagesFromPhotoBrowser(photoBrowser: DXPhotoBrowser, currentAsset: PHAsset)
    func seletedPhotosNumberInPhotoBrowser(photoBrowser: DXPhotoBrowser) -> Int
    func photoBrowser(photoBrowser: DXPhotoBrowser, currentPhotoAssetIsSeleted asset: PHAsset) -> Bool
    func photoBrowser(photoBrowser: DXPhotoBrowser, seletedAsset asset: PHAsset) -> Bool
    func photoBrowser(photoBrowser: DXPhotoBrowser, deseletedAsset asset: PHAsset)
    func photoBrowser(photoBrowser: DXPhotoBrowser, seleteFullImage fullImage: Bool)
}

class DXPhotoBrowser: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    struct DXPhotoBrowserConfig {
        static let maxSeletedNumber = 9
        static let browserCellReuseIdntifier = "DXBrowserCell"
    }
    
    var statusBarShouldBeHidden = false
    var didSavePreviousStateOfNavBar = false
    var viewIsActive = false
    var viewHasAppearedInitially = false
    // Appearance
    var previousNavBarHidden = false
    var previousNavBarTranslucent = false
    var previousNavBarStyle: UIBarStyle = .Default
    var previousStatusBarStyle: UIStatusBarStyle = .Default
    var previousNavBarTintColor: UIColor?
    var previousNavBarBarTintColor: UIColor?
    var previousViewControllerBackButton: UIBarButtonItem?
    var previousNavigationBarBackgroundImageDefault: UIImage?
    var previousNavigationBarBackgroundImageLandscapePhone: UIImage?
    
    var photosDataSource: Array<AnyObject>?
    
    private var currentIndex = 0
    private var fullImage = false
    
    // MARK: life time
    required init(photosArray: Array<AnyObject>?, currentIndex: Int, isFullImage: Bool) {
        self.currentIndex = currentIndex
        fullImage = isFullImage
        photosDataSource = photosArray
        self.init()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil);
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        previousStatusBarStyle = UIApplication.sharedApplication().statusBarStyle
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: animated)
        // Navigation bar appearance
        if (viewIsActive == false && navigationController?.viewControllers.first != self) {
            storePreviousNavBarAppearance()
        }
        setNavBarAppearance(animated)
        if viewHasAppearedInitially == false {
            viewHasAppearedInitially = true
        }
        
        browserCollectionView.contentOffset = CGPointMake(browserCollectionView.dx_width * CGFloat(currentIndex), 0)
    }
    
    override func viewWillDisappear(animated: Bool) {
        if (navigationController?.viewControllers.first != self && navigationController?.viewControllers.contains(self) == false) {
            viewIsActive = false
            restorePreviousNavBarAppearance(animated)
        }
        navigationController?.navigationBar.layer.removeAllAnimations()
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        setControlsHidden(false, animated: false)
        UIApplication.sharedApplication().setStatusBarStyle(previousStatusBarStyle, animated: animated)
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewIsActive = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        viewIsActive = false
        super.viewDidDisappear(animated)
    }
    
    // MARK: priviate
    
    private func restorePreviousNavBarAppearance(animated: Bool) {
        if didSavePreviousStateOfNavBar == true {
            navigationController?.setNavigationBarHidden(previousNavBarHidden, animated: animated)
            let navBar = navigationController!.navigationBar
            navBar.tintColor = previousNavBarBarTintColor
            navBar.translucent = previousNavBarTranslucent
            navBar.barTintColor = previousNavBarBarTintColor
            navBar.barStyle = previousNavBarStyle
            navBar.setBackgroundImage(previousNavigationBarBackgroundImageDefault, forBarMetrics: .Default)
            navBar.setBackgroundImage(previousNavigationBarBackgroundImageLandscapePhone, forBarMetrics: .Compact)
            if previousViewControllerBackButton != nil {
                let previousViewController = navigationController!.topViewController
                previousViewController?.navigationItem.backBarButtonItem = previousViewControllerBackButton
                previousViewControllerBackButton = nil
            }
        }
    }
    
    private func setNavBarAppearance(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        let navBar = navigationController!.navigationBar
        navBar.tintColor = UIColor.whiteColor()
        if navBar.respondsToSelector(Selector("setBarTintColor:")) {
            navBar.barTintColor = nil
            navBar.shadowImage = nil
        }
        navBar.translucent = true
        navBar.barStyle = .BlackTranslucent
        navBar.setBackgroundImage(nil, forBarMetrics: .Default)
        navBar.setBackgroundImage(nil, forBarMetrics: .Compact)
    }
    
    private func storePreviousNavBarAppearance() {
        didSavePreviousStateOfNavBar = true
        previousNavBarBarTintColor = navigationController?.navigationBar.barTintColor
        previousNavBarTranslucent = navigationController!.navigationBar.translucent;
        previousNavBarTintColor = navigationController!.navigationBar.tintColor;
        previousNavBarHidden = navigationController!.navigationBarHidden;
        previousNavBarStyle = navigationController!.navigationBar.barStyle;
        previousNavigationBarBackgroundImageDefault = navigationController!.navigationBar.backgroundImageForBarMetrics(.Default)
        previousNavigationBarBackgroundImageLandscapePhone = navigationController!.navigationBar.backgroundImageForBarMetrics(.Compact)
    }
    
    // MARK: convenience
    
    private func setupViews() {
        automaticallyAdjustsScrollViewInsets = false
        view.clipsToBounds = true
        view.addSubview(browserCollectionView)
        view.addSubview(toolBar)
    }
    
    // MARK: ui actions
    
    func checkButtonAction() {
        
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photosDataSource == nil ? 0 : self.photosDataSource!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(DXPhotoBrowserConfig.browserCellReuseIdntifier, forIndexPath: indexPath) as! DXBrowserCell
        // TODO: setup cell
        return cell
    }

    
    // MARK: control hide 

    private func setControlsHidden(var hidden: Bool, animated: Bool) {
        if (photosDataSource == nil || photosDataSource!.count == 0) {
            hidden = false
        }
        let animationOffSet: CGFloat = 20
        let animationDuration = (animated ? 0.35 : 0)
        statusBarShouldBeHidden = hidden
        UIView.animateWithDuration(animationDuration, animations: {[unowned self] () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
        })
        let frame = CGRectIntegral(CGRectMake(0, view.dx_height - 44, view.dx_width, 44))
        if areControlsHidden() && hidden == false && animated {
            toolBar.frame = CGRectOffset(frame, 0, animationOffSet)
        }
        UIView.animateWithDuration(animationDuration) {[unowned self] () -> Void in
            let alpha: CGFloat = hidden ? 0 : 1
            self.navigationController?.navigationBar.alpha = alpha
            self.toolBar.frame = frame
            if hidden {
                self.toolBar.frame = CGRectOffset(self.toolBar.frame, 0, animationOffSet)
            }
            self.toolBar.alpha = alpha
        }
    }
   
    override func prefersStatusBarHidden() -> Bool {
        return statusBarShouldBeHidden
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    private func areControlsHidden() -> Bool {
        return toolBar.alpha == 0
    }
    
    private func hideControls() {
        setControlsHidden(true, animated: true)
    }
    
    private func toggleControls() {
        setControlsHidden(!areControlsHidden(), animated: true)
    }
    
    // MARK: lazyload
    

    lazy var browserCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .Horizontal
        var collectionView = UICollectionView(frame: CGRectMake(-10, 0, self.view.dx_width+20, self.view.dx_height))
        collectionView.backgroundColor = UIColor.blackColor()
        collectionView .registerClass(DXBrowserCell.self, forCellWithReuseIdentifier: DXPhotoBrowserConfig.browserCellReuseIdntifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.pagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    lazy var toolBar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRectMake(0, self.view.dx_height - 44, self.view.dx_width, 44))
        toolbar.setBackgroundImage(nil, forToolbarPosition: .Any, barMetrics: .Default)
        toolbar.setBackgroundImage(nil, forToolbarPosition: .Any, barMetrics: .DefaultPrompt)
        toolbar.barStyle = .Black
        toolbar.translucent = true
        return toolbar
        }()
    
    lazy var checkButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.frame = CGRectMake(0, 0, 25, 25)
        button.setBackgroundImage(UIImage(named: "photo_check_selected"), forState: .Selected)
        button.setBackgroundImage(UIImage(named: "photo_check_default"), forState: .Normal)
        button.addTarget(self, action: Selector("checkButtonAction"), forControlEvents: .TouchUpInside)
        return button
        }()
}