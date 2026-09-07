# RATO FILE MANAGER

Projeto UIKit para iOS 15 ou posterior. O app acessa apenas o diretório `Documents` do próprio aplicativo, que é a área permitida pelo iOS para apps sem jailbreak.

## Gerar a IPA pelo GitHub Actions

Este pacote contém um projeto Xcode e o workflow `.github/workflows/build-unsigned-ipa.yml`. O workflow compila uma IPA ARM64 **sem assinatura** em um runner macOS do GitHub. Não é necessário informar Apple ID, senha, certificado ou arquivo `.p12` ao GitHub.

1. Crie um repositório no GitHub. Um repositório público pode usar os runners padrão gratuitamente; em um repositório privado, o GitHub aplica a franquia mensal da conta.
2. Envie para a raiz do repositório todos os itens deste pacote: a pasta `RatoFileManager`, a pasta `RatoFileManager.xcodeproj`, a pasta `.github` e este arquivo `README.md`.
3. Abra a aba **Actions** no repositório, escolha **Build unsigned IPA** e clique em **Run workflow**.
4. Quando o processo terminar com sucesso, abra a execução e baixe o artefato **RatoFileManager-unsigned-ipa** na seção **Artifacts**.
5. Descompacte o download. O arquivo `RatoFileManager-unsigned.ipa` estará dentro dele.
6. Envie essa IPA para o iPhone, abra-a no eSign, escolha seu certificado e assine antes de instalar.

## Observações

- A IPA produzida pelo GitHub não instala diretamente, porque não possui assinatura. A assinatura deve ocorrer no eSign usando um certificado que você controla e que esteja válido.
- Não envie senhas da Apple, certificados ou perfis de provisionamento para o repositório.
- Caso o eSign informe que o identificador do app não é aceito pelo certificado, altere `PRODUCT_BUNDLE_IDENTIFIER` no arquivo `RatoFileManager.xcodeproj/project.pbxproj` para um identificador permitido pelo seu certificado e execute o workflow novamente.
