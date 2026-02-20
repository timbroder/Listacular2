import Testing
@testable import Listacular

@Suite("ListTemplate")
struct ListTemplateTests {
    @Test("builtIn has 5 templates")
    func builtInCount() {
        #expect(ListTemplate.builtIn.count == 5)
    }

    @Test("all templates have non-empty names")
    func nonEmptyNames() {
        for template in ListTemplate.builtIn {
            #expect(!template.name.isEmpty)
        }
    }

    @Test("all templates have non-empty icons")
    func nonEmptyIcons() {
        for template in ListTemplate.builtIn {
            #expect(!template.icon.isEmpty)
        }
    }

    @Test("all templates have at least one item")
    func nonEmptyItems() {
        for template in ListTemplate.builtIn {
            #expect(!template.items.isEmpty)
        }
    }

    @Test("all template IDs are unique")
    func uniqueIDs() {
        let ids = ListTemplate.builtIn.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(ids.count == uniqueIDs.count)
    }

    @Test("expected templates exist")
    func expectedNames() {
        let names = Set(ListTemplate.builtIn.map(\.name))
        #expect(names.contains("Grocery List"))
        #expect(names.contains("Packing List"))
    }
}
