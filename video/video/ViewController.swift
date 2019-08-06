//
//  ViewController.swift
//  video
//
//  Created by harry on 2019/8/5.
//  Copyright © 2019 harry. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    
    guard let device = MTLCreateSystemDefaultDevice() else {
      print("GPU not support")
      return
    }
    
    let mView = MTKView(frame: view.frame, device: device)
    mView.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)
    
    let allocator = MTKMeshBufferAllocator(device: device)
    let mdlMesh = MDLMesh(sphereWithExtent: [0.2, 0.75, 0.2], segments: [100, 100], inwardNormals: false, geometryType: .triangles, allocator: allocator)
    
    let mesh =  try! MTKMesh(mesh: mdlMesh, device: device)
    
    guard let commandQueue = device.makeCommandQueue() else {
      print("could not create a command queue")
      return
    }
    
    let shader = """
      #include <metal_stdlib>
      using namespace metal;
      
      struct VertexIn {
        float4 position [[ attribute(0) ]];
      };

      vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) {
        return vertex_in.position;
      }

      fragment float4 fragment_main() {
        return float4(1, 0.4, 0.21, 1);
      }
    """
    
    let library = try! device.makeLibrary(source: shader, options: nil)
    let vertexFunction = library.makeFunction(name: "vertex_main")
    let fragmentFunction = library.makeFunction(name: "fragment_main")
    
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
    
    let pipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)
    
    
    guard let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderDescriptor = mView.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor) else {
        print("error")
        return
    }
    
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
    
    guard let submesh = mesh.submeshes.first else {
      print("error rrr")
      return
    }
    renderEncoder.drawIndexedPrimitives(type: .point, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: 0)
    
    renderEncoder.endEncoding()
    guard let drawable = mView.currentDrawable else {
      print("error eee")
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
    
    view.addSubview(mView)
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }


}

