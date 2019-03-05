//
//  Shader.metal
//  MetalTest
//
//  Created by Леонид Лядвейкин on 27/02/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

#include <metal_stdlib>

#define LightCount 3
using namespace metal;

struct Light {
    float3 worldPosition;
    float3 color;
};

struct FragmentUniforms {
    float3 cameraWorldPosition;
    float3 ambientLightColor;
    float3 specularColor;
    float specularPower;
    Light lights[LightCount];
};

struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float2 texCoords;
};

struct VertexUniforms {
    float4x4 viewProjectionMatrix;
    float4x4 modelMatrix;
    float3x3 normalMatrix;
};

vertex VertexOut vertex_main(VertexIn vertexIn [[stage_in]],
                             constant VertexUniforms &uniforms [[buffer(1)]])
{
    VertexOut vertexOut;
    float4 worldPosition = uniforms.modelMatrix * float4(vertexIn.position, 1);
    vertexOut.position = uniforms.viewProjectionMatrix * worldPosition;
    vertexOut.worldPosition = worldPosition.xyz;
    vertexOut.worldNormal = uniforms.normalMatrix * vertexIn.normal;
    vertexOut.texCoords = vertexIn.texCoords;
    return vertexOut;
}

fragment float4 fragment_main(VertexOut fragmentIn [[stage_in]],
                              constant FragmentUniforms &uniforms [[buffer(0)]],
                              texture2d<float, access::sample> baseColorTexture [[texture(0)]],
                              sampler baseColorSampler [[sampler(0)]])
{
    float3 baseColor = baseColorTexture.sample(baseColorSampler, fragmentIn.texCoords).rgb;
    float3 specularColor = uniforms.specularColor;
    float3 N = normalize(fragmentIn.worldNormal.xyz);
    float3 V = normalize(uniforms.cameraWorldPosition - fragmentIn.worldPosition.xyz);
   
    float3 finalColor(0, 0, 0);
    for (int i = 0; i < LightCount; ++i) {
        float3 L = normalize(uniforms.lights[i].worldPosition - fragmentIn.worldPosition.xyz);
        float3 diffuseIntensity = saturate(dot(N, L));
        float3 H = normalize(L + V);
        float specularBase = saturate(dot(N, H));
        float specularIntensity = powr(specularBase, uniforms.specularPower);
        float3 lightColor = uniforms.lights[i].color;
        finalColor += uniforms.ambientLightColor * baseColor +
        diffuseIntensity * lightColor * baseColor +
        specularIntensity * lightColor * specularColor;
    }
    
    return float4(finalColor, 1);
}
