import AuthenticationServices
import CryptoKit
import FirebaseAuth
import UIKit

@MainActor
final class SignInWithAppleCoordinator: NSObject {
    private var continuation: CheckedContinuation<Void, Error>?
    private var currentNonce: String?
    private var retainedSelf: SignInWithAppleCoordinator?

    func signIn() async throws {
        let nonce = Self.randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        retainedSelf = self

        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            controller.performRequests()
        }
    }

    private func finish(_ result: Result<Void, Error>) {
        defer {
            continuation = nil
            retainedSelf = nil
            currentNonce = nil
        }
        switch result {
        case .success:
            continuation?.resume()
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }
            for r in randoms where remaining > 0 {
                if r < charset.count {
                    result.append(charset[Int(r)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

extension SignInWithAppleCoordinator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            await processAuthorization(authorization)
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            finish(.failure(error))
        }
    }

    private func processAuthorization(_ authorization: ASAuthorization) async {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let tokenData = appleCredential.identityToken,
              let idTokenString = String(data: tokenData, encoding: .utf8) else {
            finish(.failure(URLError(.badServerResponse)))
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        do {
            _ = try await Auth.auth().signIn(with: credential)
            finish(.success(()))
        } catch {
            finish(.failure(error))
        }
    }
}

extension SignInWithAppleCoordinator: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else {
                return ASPresentationAnchor()
            }
            return window
        }
    }
}
