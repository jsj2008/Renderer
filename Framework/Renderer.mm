//
//  Renderer.m
//  Renderer
//
//  Created by Benjamin Gregorski on 11/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <ImageIO/ImageIO.h>

#import "Renderer.h"
#import "Camera.h"
#import "FrameBuffer.h"

#include "Scene.h"
#include "SceneObject.h"
#include "Sphere.h"
#include "Plane.h"
#include "BasicTypesImpl.h"
#include "PointLightSource.h"  

using namespace Framework;

@implementation Renderer
{
    Camera * m_cam;
    FrameBuffer * m_fb;
    Scene * m_scene;
}

@synthesize name;

-(void) init: (NSString*) n
{
    /*
     Camera (0,0,10) looking at 0,0,0
     Sphere at (0,0,0) radius 5.
     
     Light at (0,0,10)
     */
    PointF camPos(0,0,10);
    VectorF camDir(0,0,-1);
    Ray r(camPos, camDir);
    VectorF up(0,1,0);
    
    m_cam = [[Camera alloc] init:r upV:up Fov:45 AspectRatio:1.0f nearPlane:5.0f];
    m_fb = [[FrameBuffer alloc] init:100 height:100];

    m_scene = new Scene();
    self.name  = n;
    
    vec3 pos(0,0,0);
    Sphere * so = new Sphere(2.0f, pos);
    
    PointF planePos(0, 0, -20);
    VectorF planeN(0,0,1);
    Plane * plane = new Plane(planePos, planeN);
    
    Color ambient(0,0,0,1);
    Color diffuse(0.25,0.25,0.25,1);
    Color specular(0,0,0,0);
    
    PointF lightPos(5,0,5);
    PointLightSource *p0 = new PointLightSource(lightPos, ambient, diffuse, specular, 1.0f);
    m_scene->addLight(p0);
 
    Color diffuse2(0.5,0.5,0.5,1);
    PointF light2Pos(-5,0,5);
    PointLightSource* p1 = new PointLightSource(light2Pos, ambient, diffuse2, specular, 1.0f);
    m_scene->addLight(p1);
    
    m_scene->addSceneObject(so);
    m_scene->addSceneObject(plane);
}

-(void) render: (NSString**) options
{
    // Grab view screen from camera and cast rays
    // thrrough pixel centers.
    Rectangle viewScreen = [m_cam getNearPlane];
    m_scene->setViewPoint([m_cam getPos]);
    
    float upStep = viewScreen.upLen / m_fb.height;
    float rightStep = viewScreen.rightLen / m_fb.width;
    
    float upStartOffset = upStep/2;
    float rightStartOffset = rightStep/2;
    
    // Generate pixels and cast rays
    for(int h = 0; h < m_fb.height; ++h) {
        VectorF pixelOffsetVec = Math::vec3AXPlusBY(viewScreen.upV, (upStep*h + upStartOffset), viewScreen.rightV, rightStartOffset);
        PointF pixelCenter = Math::vec3APlusB(viewScreen.bottomLeft, pixelOffsetVec);
        
        VectorF rightInc = Math::vec3Scale(viewScreen.rightV, rightStep);
        for (int w = 0; w < m_fb.width; ++w) {
            VectorF castDir = Math::vec3AMinusB(pixelCenter, [m_cam getPos]);
            Math::vec3Normalize(castDir);
            pixelCenter.increment(rightInc);
            
            Ray r([m_cam getPos], castDir);
            Color c = m_scene->traceRay(r);
            Pixel * p = [m_fb getPixel:w height:h];
            p->c = c;
        }
    }
       
    // Save Pixel buffer to file
    [m_fb exportToFile:@"/Users/bfgorski/image.png"
                format:@""
                 width:100
                height:100
               options:@{ @"topRowFirst" : [NSNumber numberWithBool:YES] }
     ];
}

-(void) parseOptions
{
    
}

+(int) numInstances
{
    return 1;
}

-(void) runUnitTests
{
    
}
@end
