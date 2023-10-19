//
//  CompressVideo.swift
//  Adrenaline
//
//  https://stackoverflow.com/a/62862102/22068672
//

import AVFoundation

class CompressVideo {
    // add these properties
    var assetWriter: AVAssetWriter!
    var assetWriterVideoInput: AVAssetWriterInput!
    var audioMicInput: AVAssetWriterInput!
    var videoURL: URL!
    var audioAppInput: AVAssetWriterInput!
    var channelLayout = AudioChannelLayout()
    var assetReader: AVAssetReader?
    let bitrate: NSNumber = NSNumber(value: 1250000) 
    /* you can change this number to increase/decrease the quality. The more you increase, the
     * better the video quality but the the compressed file size will also increase */

    /* compression function, it returns a .mp4 but you can change it to .mov inside the do try block
     * towards the middle. Change assetWriter = try AVAssetWriter ... AVFileType.mp4 to
     * AVFileType.mov */
    func compressFile(_ urlToCompress: URL, completion:@escaping (URL)->Void) async throws {
        print("Initial URL to compress: \(urlToCompress.absoluteString)")
        var audioFinished = false
        var videoFinished = false
        
        let asset = AVAsset(url: urlToCompress)
        
        //create asset reader
        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch {
            assetReader = nil
        }
        
        guard let reader = assetReader else {
            print("Could not initialize asset reader probably failed its try catch")
            // show user error message/alert
            return
        }
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: AVMediaType.video).first 
        else { return }
        let videoReaderSettings: [String:Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB]
        
        let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, 
                                                              outputSettings: videoReaderSettings)
        
        var assetReaderAudioOutput: AVAssetReaderTrackOutput?
        if let audioTrack = try await asset.loadTracks(withMediaType: AVMediaType.audio).first {
            
            let audioReaderSettings: [String : Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2
            ]
            
            assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, 
                                                              outputSettings: audioReaderSettings)
            
            if reader.canAdd(assetReaderAudioOutput!) {
                reader.add(assetReaderAudioOutput!)
            } else {
                print("Couldn't add audio output reader")
                // show user error message/alert
                return
            }
        }
        
        if reader.canAdd(assetReaderVideoOutput) {
            reader.add(assetReaderVideoOutput)
        } else {
            print("Couldn't add video output reader")
            // show user error message/alert
            return
        }
        
        let videoSettings:[String:Any] = await [
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: self.bitrate],
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoHeightKey: try videoTrack.load(.naturalSize).height,
            AVVideoWidthKey: try videoTrack.load(.naturalSize).width,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
        ]
        
        let audioSettings: [String:Any] = [AVFormatIDKey : kAudioFormatMPEG4AAC,
                                   AVNumberOfChannelsKey : 2,
                                         AVSampleRateKey : 44100.0,
                                      AVEncoderBitRateKey: 128000
        ]
        
        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, 
                                            outputSettings: audioSettings)
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, 
                                            outputSettings: videoSettings)
        videoInput.transform = try await videoTrack.load(.preferredTransform)
        
        let videoInputQueue = DispatchQueue(label: "videoQueue")
        let audioInputQueue = DispatchQueue(label: "audioQueue")
        
        do {
            let pathname = urlToCompress.deletingPathExtension().absoluteString
            print("Pathname: \(pathname)")
            let outputPath = "\(pathname)-compressed.mp4"
            guard let outputURL = URL(string: outputPath) else {
                print("Invalid output URL")
                throw NSError()
            }
            print("Output URL: \(outputURL.absoluteString)")
            
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4)
            
        } catch {
            assetWriter = nil
        }
        guard let writer = assetWriter else {
            print("assetWriter was nil")
            // show user error message/alert
            return
        }
        
        writer.shouldOptimizeForNetworkUse = true
        writer.add(videoInput)
        writer.add(audioInput)
        
        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: CMTime.zero)
        
        let closeWriter:()->Void = {
            if (audioFinished && videoFinished) {
                self.assetWriter?.finishWriting(completionHandler: { [weak self] in
                    
                    if let assetWriter = self?.assetWriter {
                        do {
                            let data = try Data(contentsOf: assetWriter.outputURL)
                            print(
                                "compressFile -file size after compression: \(Double(data.count / 1048576)) mb")
                        } catch let err as NSError {
                            print("compressFile Error: \(err.localizedDescription)")
                        }
                    }
                    
                    if let safeSelf = self, let assetWriter = safeSelf.assetWriter {
                        completion(assetWriter.outputURL)
                    }
                })
                
                self.assetReader?.cancelReading()
            }
        }
        
        audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
            while(audioInput.isReadyForMoreMediaData) {
                if let cmSampleBuffer = assetReaderAudioOutput?.copyNextSampleBuffer() {
                    
                    audioInput.append(cmSampleBuffer)
                    
                } else {
                    audioInput.markAsFinished()
                    DispatchQueue.main.async {
                        audioFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }
        
        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
            // request data here
            while(videoInput.isReadyForMoreMediaData) {
                if let cmSampleBuffer = assetReaderVideoOutput.copyNextSampleBuffer() {
                    
                    videoInput.append(cmSampleBuffer)
                    
                } else {
                    videoInput.markAsFinished()
                    DispatchQueue.main.async {
                        videoFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }
    }
}
