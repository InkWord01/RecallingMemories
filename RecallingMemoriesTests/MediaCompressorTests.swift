//
//  MediaCompressorTests.swift
//  RecallingMemoriesTests
//
//  注意：图片压缩用 ImageIO 同步路径，可在测试中跑；
//        视频压缩依赖 AVAssetExportSession，集成测试更合适，本文件仅做配置常量验证。
//

import XCTest
import UIKit
@testable import RecallingMemories

final class MediaCompressorTests: XCTestCase {

    // MARK: - 图片压缩

    func testCompressLargeImageDownsamples() {
        // 造一张 4096x3072 的纯色 PNG（远超 maxDimension 2048）
        let big = renderImage(size: CGSize(width: 4096, height: 3072), color: .red)
        guard let bigData = big.pngData() else {
            return XCTFail("无法生成测试图片")
        }

        guard let compressed = MediaCompressor.compressImage(bigData) else {
            return XCTFail("压缩失败")
        }
        guard let resultImage = UIImage(data: compressed) else {
            return XCTFail("压缩后数据无法解码")
        }

        // 长边应被限制到 maxDimension
        let longest = max(resultImage.size.width * resultImage.scale,
                          resultImage.size.height * resultImage.scale)
        XCTAssertLessThanOrEqual(longest, MediaCompressor.ImageConfig.maxDimension + 1,
                                  "长边超过 maxDimension")
    }

    func testCompressedDataIsSmallerThanOriginal() {
        let big = renderImage(size: CGSize(width: 4096, height: 3072), color: .blue)
        guard let bigData = big.pngData() else {
            return XCTFail("无法生成测试图片")
        }

        guard let compressed = MediaCompressor.compressImage(bigData) else {
            return XCTFail("压缩失败")
        }
        XCTAssertLessThan(compressed.count, bigData.count, "压缩后应明显小于原图")
    }

    func testInvalidDataReturnsNil() {
        let garbage = "not an image".data(using: .utf8)!
        XCTAssertNil(MediaCompressor.compressImage(garbage))
    }

    func testSmallImagePassesThroughBelowMax() {
        // 输入小于 maxDimension 的图，应直接通过（不放大）
        let small = renderImage(size: CGSize(width: 800, height: 600), color: .green)
        guard let smallData = small.pngData() else {
            return XCTFail("无法生成测试图片")
        }
        guard let compressed = MediaCompressor.compressImage(smallData) else {
            return XCTFail("压缩失败")
        }
        guard let resultImage = UIImage(data: compressed) else {
            return XCTFail("压缩后数据无法解码")
        }

        let longest = max(resultImage.size.width * resultImage.scale,
                          resultImage.size.height * resultImage.scale)
        // ImageIO thumbnail 不会放大，应保持 ≤ 800
        XCTAssertLessThanOrEqual(longest, 800 + 1)
    }

    // MARK: - 配置常量

    func testConfigSensible() {
        XCTAssertEqual(MediaCompressor.ImageConfig.maxDimension, 2048)
        XCTAssertEqual(MediaCompressor.VideoConfig.maxDuration, 30)
        XCTAssertEqual(MediaCompressor.ImageConfig.jpegQuality, 0.85, accuracy: 0.001)
    }

    // MARK: - 辅助

    private func renderImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
