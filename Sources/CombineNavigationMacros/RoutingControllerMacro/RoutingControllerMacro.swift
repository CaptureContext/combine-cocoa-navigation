import MacroToolkit
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct RoutingControllerMacro {
	static let moduleName = "CombineNavigation"
	static let conformanceName = "RoutingController"
	static var qualifiedConformanceName: String { "\(Self.moduleName).\(Self.conformanceName)" }
	static var conformanceNames: [String] { [Self.conformanceName, Self.qualifiedConformanceName] }
}

extension RoutingControllerMacro: ExtensionMacro {
	public static func expansion<
		Declaration: DeclGroupSyntax,
		Type: TypeSyntaxProtocol,
		Context: MacroExpansionContext
	>(
		of node: AttributeSyntax,
		attachedTo declaration: Declaration,
		providingExtensionsOf type: Type,
		conformingTo protocols: [TypeSyntax],
		in context: Context
	) throws -> [ExtensionDeclSyntax] {
		guard let decl = ClassDeclSyntax(declaration) else {
			return context.diagnose(.requiresClassDeclaration(declaration), return: [])
		}

		let alreadyConforms = decl.inheritanceClause?.inheritedTypes.contains(where: {
			Self.conformanceNames.contains($0.type.trimmedDescription)
		}) == true

		if alreadyConforms { return [] }

		var extensionDecl: ExtensionDeclSyntax = {
			let decl: DeclSyntax = """
			extension \(type.trimmed): \(raw: Self.qualifiedConformanceName) {}
			"""
			return decl.cast(ExtensionDeclSyntax.self)
		}()

		do {
			extensionDecl.memberBlock = MemberBlockSyntax(
				members: MemberBlockItemListSyntax(
					try makeDeclarationsExtensionMembers(for: decl)
				)
			).with(\.leadingTrivia, .newline)
		} catch {
			return (error as! DiagnosticsError).diagnostics.first.map { diagnostic in
				context.diagnose(diagnostic, return: [ExtensionDeclSyntax]())
			} ?? []
		}

		return [extensionDecl]
	}
}

fileprivate extension Diagnostic {
	static func requiresClassDeclaration(_ node: some DeclGroupSyntax) -> Self {
		func _requiresClassDeclaration(_ node: some SyntaxProtocol) -> Self {
			DiagnosticBuilder(for: node)
				.messageID(domain: "RoutingController", id: "requires_class_declaration")
				.message("`@RoutingController` must be attached to a class declaration.")
				.build()
		}

		return node.as(EnumDeclSyntax.self).map { decl in
			_requiresClassDeclaration(decl.enumKeyword)
		} ?? node.as(StructDeclSyntax.self).map { decl in
			_requiresClassDeclaration(decl.structKeyword)
		} ?? node.as(ActorDeclSyntax.self).map { decl in
			_requiresClassDeclaration(decl.actorKeyword)
		} ?? {
			_requiresClassDeclaration(node)
		}()
	}

	static func requiresDictionaryLiteralForStackDestination(_ node: AttributeSyntax) -> Self {
		DiagnosticBuilder(for: node)
			.messageID(domain: "RoutingController", id: "requires_dictionary_literal_for_stack_destination")
			.message("""
			`@StackDestination` requires explicit wrapper type \
			or dictionary type literal declaration for value.
			""")
			.build()
	}
}
