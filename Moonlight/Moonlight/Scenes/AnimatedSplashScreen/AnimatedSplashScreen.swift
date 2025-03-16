//
//  AnimatedSplashScreen.swift
//  Moonlight
//
//  Created by Gennady Dmitrik on 17.01.23.
//

// MARK: Custom View Builder
import SwiftUI

struct AnimatedSplashScreen<Content: View>: View {
    var content: Content

    // MARK: Properties
    let color = Color("Black")
    var animationTiming = 0.65
    let onAnimationEnd: () -> ()
    @EnvironmentObject private var viewModel: MoonlightViewModel

    // MARK: Animation Properties
    @State var startAnimation = false
    @State var animateContent = false
    @Namespace var animation

    init(
        animationTiming: Double = 0.65,
        @ViewBuilder content: @escaping () -> Content,
        onAnimationEnd: @escaping () -> ()
    ) {
        self.content = content()
        self.onAnimationEnd = onAnimationEnd
        self.animationTiming = animationTiming
    }

    var body: some View {
        VStack {
            if startAnimation {
                GeometryReader { proxy in
                    let size = proxy.size
                    VStack {
                        let topOffset = safeArea().top > 0 ? safeArea().top - 20 : 0
                        ZStack(alignment: .top) {
                            Rectangle()
                                .fill(color)
                                .matchedGeometryEffect(id: "SplashColor", in: animation)
                            MoonView()
                                .environmentObject(viewModel)
                                .aspectRatio(contentMode: .fill)
                                .matchedGeometryEffect(id: "SplashIcon", in: animation)
                                .padding(.top, topOffset)
                                .padding(.leading, animateContent ? 0 : -size.height / 2)
                        }
                        .ignoresSafeArea(.container, edges: .all)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    ZStack {
                            content
                            .padding(.bottom, animateContent ? size.height : proxy.size.height / 2)
                    }
                    .offset(y: proxy.size.height / 2 - 40)
                }
                .transition(.identity)
                .ignoresSafeArea(.container, edges: .all)
                .onAppear {
                    if !animateContent {
                        withAnimation(.easeInOut(duration: animationTiming)) {
                            animateContent = true
                        }
                    }
                }
            } else {
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(color)
                        .matchedGeometryEffect(id: "SplashColor", in: animation)
                }
                .ignoresSafeArea(.container, edges: .all)
            }
        }
        .onAppear {
            if !startAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: animationTiming)) {
                        startAnimation = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + animationTiming - 0.05) {
                    onAnimationEnd()
                }
            }
        }
    }
}
