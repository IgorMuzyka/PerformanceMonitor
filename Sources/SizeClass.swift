
import CoreFoundation.CFCGTypes

public enum SizeClass: Equatable, CaseIterable {
    public static var allCases: [Self] {
        ToolbarSizeClass.allCases.map { .toolbar($0) } + [.compact, .regular]
    }
    func next() -> SizeClass? {
        guard let index = Self.allCases.firstIndex(of: self) else { return .none }
        let next = Self.allCases.index(after: index)
        guard next < Self.allCases.endIndex else { return .none }
        return Self.allCases[next]
    }
    func previous() -> SizeClass? {
        guard let index = Self.allCases.firstIndex(of: self) else { return .none }
        let previous = Self.allCases.index(before: index)
        guard previous >= Self.allCases.startIndex else { return .none }
        return Self.allCases[previous]
    }
    public enum ToolbarSizeClass: Equatable, CaseIterable {
        case compact
        case regular
        case expanded
        public static var allCases: [Self] {
            [.compact, .regular]
        }
    }
    case toolbar(ToolbarSizeClass = .regular)
    case regular
    case compact
    var scale: CGSize {
        switch self {
            case .compact: return CGSize(width: 1, height: 1)
            case .regular: return CGSize(width: 1, height: 1)
            case .toolbar(let toolbar):
                switch toolbar {
                    case .compact: return CGSize(width: 0.5, height: 0.5)
                    case .regular: return CGSize(width: 0.75, height: 0.75)
                    case .expanded: return CGSize(width: 1, height: 1)
                }
        }
    }
}
