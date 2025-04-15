//
//  SlideshowViewController.swift
//  ZoomableApp
//
//  Created by Phil Wright on 4/10/25.
//

import UIKit
import AVFoundation

// Slide item model to pair images with audio
struct SlideItem {
    let imageName: String
    let audioFileName: String
}

class SlideshowViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // Array of slide items containing both image and audio references
    let slideItems: [SlideItem] = [
        SlideItem(imageName: "s1L", audioFileName: "s1"),
        SlideItem(imageName: "s2L", audioFileName: "s2"),
        SlideItem(imageName: "s3L", audioFileName: "s3"),
        SlideItem(imageName: "s4L", audioFileName: "s4"),
        SlideItem(imageName: "s5L", audioFileName: "s5"),
        SlideItem(imageName: "s6L", audioFileName: "s6"),
        SlideItem(imageName: "s7L", audioFileName: "s7"),
        SlideItem(imageName: "s8L", audioFileName: "s8"),
        SlideItem(imageName: "s9L", audioFileName: "s9"),
    ]
    
    // Audio player
    private var audioPlayer: AVAudioPlayer?
    
    // Track the current visible slide
    private var currentVisibleIndex: Int = 0
    
    // Player control bar
    private let playerControlBar = UIView()
    private let playButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let currentSlideLabel = UILabel()
    
    // Collection View
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SlideshowCell.self, forCellWithReuseIdentifier: SlideshowCell.identifier)
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupPlayerControlBar()
        setupCollectionView()
        updateSlideLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Play audio for the first slide when view appears
        playAudioForCurrentSlide()
    }
    
    // MARK: - Setup UI
    
    private func setupPlayerControlBar() {
        // Configure player control bar
        playerControlBar.backgroundColor = .systemGray6
        playerControlBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerControlBar)
        
        // Add shadow to make it look like a navigation bar
        playerControlBar.layer.shadowColor = UIColor.black.cgColor
        playerControlBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        playerControlBar.layer.shadowOpacity = 0.2
        playerControlBar.layer.shadowRadius = 2
        
        // Setup play button
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playerControlBar.addSubview(playButton)
        
        // Setup pause button
        pauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        pauseButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        playerControlBar.addSubview(pauseButton)
        
        // Setup stop button
        stopButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        playerControlBar.addSubview(stopButton)
        
        // Setup slide label
        currentSlideLabel.font = UIFont.systemFont(ofSize: 14)
        currentSlideLabel.textAlignment = .right
        currentSlideLabel.translatesAutoresizingMaskIntoConstraints = false
        playerControlBar.addSubview(currentSlideLabel)
        
        // Setup constraints for the player control bar
        NSLayoutConstraint.activate([
            playerControlBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerControlBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerControlBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerControlBar.heightAnchor.constraint(equalToConstant: 50),
            
            playButton.centerYAnchor.constraint(equalTo: playerControlBar.centerYAnchor),
            playButton.leadingAnchor.constraint(equalTo: playerControlBar.leadingAnchor, constant: 20),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            pauseButton.centerYAnchor.constraint(equalTo: playerControlBar.centerYAnchor),
            pauseButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 20),
            pauseButton.widthAnchor.constraint(equalToConstant: 44),
            pauseButton.heightAnchor.constraint(equalToConstant: 44),
            
            stopButton.centerYAnchor.constraint(equalTo: playerControlBar.centerYAnchor),
            stopButton.leadingAnchor.constraint(equalTo: pauseButton.trailingAnchor, constant: 20),
            stopButton.widthAnchor.constraint(equalToConstant: 44),
            stopButton.heightAnchor.constraint(equalToConstant: 44),
            
            currentSlideLabel.centerYAnchor.constraint(equalTo: playerControlBar.centerYAnchor),
            currentSlideLabel.trailingAnchor.constraint(equalTo: playerControlBar.trailingAnchor, constant: -20),
            currentSlideLabel.leadingAnchor.constraint(equalTo: stopButton.trailingAnchor, constant: 20)
        ])
    }
    
    // Setup collection view constraints
    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: playerControlBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Audio Control
    
    // Play audio for the current slide
    private func playAudioForCurrentSlide() {
        // Stop any currently playing audio
        audioPlayer?.stop()
        
        // Get the audio file name for the current slide
        let audioFileName = slideItems[currentVisibleIndex].audioFileName
        
        // Path to audio file in project resources
        if let audioPath = Bundle.main.path(forResource: "\(audioFileName)", ofType: "mp3") {
            let audioURL = URL(fileURLWithPath: audioPath)
            
            do {
                // Initialize and play the audio
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Error playing audio file: \(error.localizedDescription)")
            }
        } else {
            print("Audio file not found: \(audioFileName).mp3")
        }
    }
    
    // Update the slide number label
    private func updateSlideLabel() {
        currentSlideLabel.text = "Slide \(currentVisibleIndex + 1) of \(slideItems.count)"
    }
    
    // MARK: - Button Actions
    
    @objc private func playButtonTapped() {
        if audioPlayer?.isPlaying == false {
            audioPlayer?.play()
        } else if audioPlayer == nil {
            playAudioForCurrentSlide()
        }
    }
    
    @objc private func pauseButtonTapped() {
        audioPlayer?.pause()
    }
    
    @objc private func stopButtonTapped() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slideItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SlideshowCell.identifier, for: indexPath) as? SlideshowCell else {
            fatalError("Unable to dequeue SlideshowCell")
        }
        let slideItem = slideItems[indexPath.item]
        cell.configure(with: slideItem.imageName)
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Calculate which page is currently visible after scrolling stops
        let pageWidth = scrollView.frame.size.width
        let page = Int(floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
        
        // Update current index and play audio if it's a different slide
        if currentVisibleIndex != page && page >= 0 && page < slideItems.count {
            currentVisibleIndex = page
            updateSlideLabel()
            playAudioForCurrentSlide()
        }
    }
}

// MARK: - SlideshowCell

class SlideshowCell: UICollectionViewCell {

    static let identifier = "SlideshowCell"

    private let zoomableImageView = ZoomableImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(zoomableImageView)
        zoomableImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zoomableImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            zoomableImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            zoomableImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            zoomableImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with imageName: String) {
        zoomableImageView.setImage(named: imageName)
    }
}

// MARK: - ZoomableImageView

class ZoomableImageView: UIView, UIScrollViewDelegate {

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()
        setupImageView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    func setImage(named imageName: String) {
        imageView.image = UIImage(named: imageName)
    }

    // UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
