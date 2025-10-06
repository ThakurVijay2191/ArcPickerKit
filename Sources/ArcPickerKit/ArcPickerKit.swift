// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// A customizable semi-circular picker that allows users to select values along an arc.
///
/// `ArcPicker` presents a horizontal scrolling arc where each tick represents a discrete integer
/// in the given range. It provides a natural, dial-like interface for numeric selection such as
/// weight, distance, speed, or temperature.
///
/// The picker uses a `ScrollView` internally to enable smooth and precise scrolling,
/// with visual feedback provided via configurable tints and stroke styles.
///
/// Example:
/// ```swift
/// @State private var weight = 70
///
/// ArcPicker(range: 5...150, selectedValue: $weight) { value in
///     Text("\(value) kg")
///         .font(.title2)
///         .bold()
/// }
/// .frame(height: 200)
/// ```
///
/// - Note: Available on iOS 18.0 and later.
@available(iOS 18.0, *)
public struct ArcPicker<Label: View>: View {
    
    // MARK: - Stored Properties
    
    /// The inclusive range of selectable integer values.
    var range: ClosedRange<Int>
    
    /// The currently selected value bound to an external state.
    @Binding var selectedValue: Int
    
    /// The configuration object defining visual appearance and behavior.
    var config: ArcPickerConfig
    
    /// A closure that returns the label view for the active tick value.
    var label: (Int) -> Label
    
    /// The currently active tick position (internal state).
    @State private var activePosition: Int?
    
    
    // MARK: - Initializer
    
    /// Creates a new instance of `ArcPicker`.
    ///
    /// - Parameters:
    ///   - range: The inclusive range of selectable integer values.
    ///   - selectedValue: A binding to the currently selected value.
    ///   - config: A configuration defining the appearance and interaction behavior.
    ///     Defaults to ``ArcPickerConfig/init()``.
    ///   - label: A view builder closure providing the label view for the active tick value.
    ///
    /// Example:
    /// ```swift
    /// ArcPicker(range: 0...100, selectedValue: $value) { value in
    ///     Text("\(value)")
    /// }
    /// ```
    public init(
        range: ClosedRange<Int>,
        selectedValue: Binding<Int>,
        config: ArcPickerConfig = .init(),
        @ViewBuilder label: @escaping (Int) -> Label
    ) {
        self.range = range
        self._selectedValue = selectedValue
        self.config = config
        self.label = label
        self.activePosition = activePosition
    }
    
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let width = size.width - (config.strokeStyle.lineWidth)
            let dia = min(max(width, size.height), width)
            let radius = dia / 2
            
            WheelPath(size, radius: radius)
                .stroke(config.strokeColor, style: config.strokeStyle)
                .overlay {
                    WheelPickerScrollView(size: size, radius: radius)
                }
                .compositingGroup()
                .offset(y: -config.strokeStyle.lineWidth / 2)
        }
        .frame(height: config.height)
        .task {
            guard activePosition == nil else { return }
            activePosition = selectedValue
        }
        .onChange(of: activePosition) { oldValue, newValue in
            if let newValue, selectedValue != newValue {
                selectedValue = newValue
            }
        }
        .onChange(of: selectedValue) { oldValue, newValue in
            if activePosition != newValue {
                activePosition = newValue
            }
        }
        .onScrollPhaseChange { oldPhase, newPhase in
            if newPhase == .idle {
                Task {
                    activePosition = nil
                    try? await Task.sleep(for: .seconds(0))
                    activePosition = selectedValue
                }
            }
        }
    }
    
    
    // MARK: - Computed Properties
    
    /// A list of integer ticks generated from the provided range.
    var ticks: [Int] {
        stride(from: range.lowerBound, through: range.upperBound, by: 1).compactMap { $0 }
    }
    
    
    // MARK: - Subviews
    
    /// The scrollable wheel view containing tick marks and active label.
    ///
    /// - Parameters:
    ///   - size: The available size from the parent geometry reader.
    ///   - radius: The radius used to define the arc path.
    @ViewBuilder
    func WheelPickerScrollView(size: CGSize, radius: CGFloat) -> some View {
        let wheelShape = WheelPath(size, radius: radius)
            .strokedPath(config.strokeStyle)
        
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(ticks, id: \.self) { tick in
                    TickView(tick, size: size, radius: radius)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .safeAreaPadding(.horizontal, (size.width - 8) / 2)
        .scrollPosition(id: $activePosition, anchor: .center)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .clipShape(wheelShape)
        .contentShape(config.isCompleteInteractionEnabled ? AnyShape(.rect) : AnyShape(wheelShape))
        .overlay(alignment: .bottom) {
            // Active marker line and dot
            let strokeWidth = config.strokeStyle.lineWidth
            let halfStrokeWidth = strokeWidth / 2
            
            VStack(spacing: -5) {
                Capsule()
                    .fill(config.activeTint)
                    .frame(width: 5, height: strokeWidth)
                Circle()
                    .fill(config.activeTint)
                    .frame(width: 10, height: 10)
            }
            .offset(y: -radius + halfStrokeWidth)
        }
        .overlay(alignment: .bottom) {
            if let activePosition {
                label(activePosition)
                    .frame(
                        maxWidth: radius,
                        maxHeight: radius - (config.strokeStyle.lineWidth / 2)
                    )
            }
        }
    }
    
    
    /// Creates an individual tick mark view along the wheel path.
    ///
    /// - Parameters:
    ///   - value: The integer value represented by this tick.
    ///   - size: The available size of the wheel.
    ///   - radius: The radius of the arc path.
    @ViewBuilder
    func TickView(_ value: Int, size: CGSize, radius: CGFloat) -> some View {
        let strokeWidth = config.strokeStyle.lineWidth
        let halfStrokeWidth = strokeWidth / 2
        let isLargeTick = (ticks.firstIndex(of: value) ?? 0) % config.largeTickFrequency == 0
        
        GeometryReader { proxy in
            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
            let midX = proxy.frame(in: .scrollView(axis: .horizontal)).midX
            let halfWidth = size.width / 2
            
            let progress = max(min(midX / halfWidth, 1), -1)
            let rotation = Angle(degrees: progress * 180)
            
            Capsule()
                .fill(config.inactiveTint)
                .offset(y: -radius + halfStrokeWidth)
                .rotationEffect(rotation, anchor: .bottom)
                .offset(x: -minX)
        }
        .frame(width: 3, height: isLargeTick ? (strokeWidth - 10) : halfStrokeWidth)
        .frame(width: 8, alignment: .leading)
    }
    
    
    /// Constructs the half-circle arc path used for the wheel.
    ///
    /// - Parameters:
    ///   - size: The geometry size from the parent container.
    ///   - radius: The radius defining the curvature of the arc.
    ///
    /// - Returns: A `Path` representing a semi-circular arc.
    func WheelPath(_ size: CGSize, radius: CGFloat) -> Path {
        Path { path in
            path.addArc(
                center: .init(x: size.width / 2, y: size.height),
                radius: radius,
                startAngle: .init(degrees: 180),
                endAngle: .init(degrees: 0),
                clockwise: false
            )
        }
    }
    
    
    // MARK: - Configuration
    
    /// Defines the visual and behavioral configuration for an ``ArcPicker`` instance.
    public struct ArcPickerConfig {
        
        /// The tint color for the active marker and label.
        public var activeTint: Color
        
        /// The tint color for inactive tick marks.
        public var inactiveTint: Color
        
        /// The frequency at which large tick marks appear.
        public var largeTickFrequency: Int
        
        /// The stroke style used to draw the arc path.
        public var strokeStyle: StrokeStyle
        
        /// The stroke color of the wheel’s arc.
        public var strokeColor: Color
        
        /// The overall height of the picker.
        public var height: CGFloat
        
        /// A Boolean value that determines whether scrolling interaction
        /// is enabled across the entire picker surface or only along the arc.
        public var isCompleteInteractionEnabled: Bool
        
        /// Creates a new configuration for ``ArcPicker``.
        ///
        /// - Parameters:
        ///   - activeTint: The tint color for the active marker and label. Defaults to `.primary`.
        ///   - inactiveTint: The tint color for inactive tick marks. Defaults to `.gray`.
        ///   - largeTickFrequency: The spacing frequency of large tick marks. Defaults to `10`.
        ///   - strokeStyle: The stroke style applied to the arc. Defaults to rounded line caps and joins.
        ///   - strokeColor: The color of the arc stroke. Defaults to `.black.opacity(0.1)`.
        ///   - height: The overall picker height. Defaults to `200`.
        ///   - isCompleteInteractionEnabled: Enables full-area scrolling interaction. Defaults to `true`.
        public init(
            activeTint: Color = .primary,
            inactiveTint: Color = .gray,
            largeTickFrequency: Int = 10,
            strokeStyle: StrokeStyle = .init(lineWidth: 50, lineCap: .round, lineJoin: .round),
            strokeColor: Color = .black.opacity(0.1),
            height: CGFloat = 200,
            isCompleteInteractionEnabled: Bool = true
        ) {
            self.activeTint = activeTint
            self.inactiveTint = inactiveTint
            self.largeTickFrequency = largeTickFrequency
            self.strokeStyle = strokeStyle
            self.strokeColor = strokeColor
            self.height = height
            self.isCompleteInteractionEnabled = isCompleteInteractionEnabled
        }
    }
}
