[English](README.md) | [Español](README_ES.md) | [简体中文](README_CN.md) | [繁體中文](README_TW.md) | [日本語](README_JP.md) | [한국어](README_KR.md) | [Polski](README_PL.md) | **Português (Brasil)** | [Türkçe](README_TR.md) | [Русский](README_RU.md) | [Tiếng Việt](README_VI.md) | [Indonesia](README_ID.md) | [עברית](README_IW.md) | [हिंदी](README_IN.md) | [Italiano](README_IT.md)

# Device Access

Este fork mantém uma variante pessoal do KernelSU para root temporário com
[DFRoot](https://github.com/diabl0w/DFRoot). O gerenciador usa o nome
**Device Access**, o pacote `dev.bruno.deviceaccess` e um módulo de kernel
compilado para reconhecer seu certificado.

A branch `main` reúne a variante mantida. A `customManager` registra sua
implementação inicial, integrada à `main`; novas alterações partem da `main`.
O alvo validado é o Redmi 15 com Android 16, arquitetura ARM64 e KMI
`android13-5.15`. O KMI identifica a interface do kernel.

Mantenha **Device Access + DFRoot**: o primeiro gerencia o root e fornece o
módulo; o segundo o carrega. Basta um gerenciador KernelSU. A probe de diagnóstico
usada no desenvolvimento é opcional.

Para usar, baixe o APK assinado em
[Releases](https://github.com/BRUN0R2/KernelSU/releases/latest), confira o SHA-256
em `SHA256SUMS.txt`, instale-o e selecione **Device Access** no DFRoot.
Ao trocar o kernel de outro gerenciador, reinicie e deixe o DFRoot ativar o root.
Confirme o reconhecimento do novo gerenciador antes de remover o anterior.

O workflow **Device Access** compila e executa o lint em alterações dos arquivos
de compilação na `main` e em PRs para ela. O artefato `customManagerUnsigned`
contém o APK sem assinatura, o módulo e seus hashes; a assinatura é feita
localmente. A chave privada permanece fora do repositório.

- [Visão geral do projeto](../README.md)
- [Configuração, assinatura e atualizações](../customManager/README.md)
- [Configuração atual](../customManager/config.json)

A documentação herdada do KernelSU continua abaixo.

# KernelSU

<img src="https://kernelsu.org/logo.png" style="width: 96px;" alt="logo">

Uma solução root baseada em kernel para dispositivos Android.

[![Latest release](https://img.shields.io/github/v/release/tiann/KernelSU?label=Release&logo=github)](https://github.com/tiann/KernelSU/releases/latest)
[![Weblate](https://img.shields.io/badge/Localização-Weblate-teal?logo=weblate)](https://hosted.weblate.org/engage/kernelsu)
[![Channel](https://img.shields.io/badge/Seguir-Telegram-blue.svg?logo=telegram)](https://t.me/KernelSU)
[![License: GPL v2](https://img.shields.io/badge/Licença-GPL%20v2-orange.svg?logo=gnu)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![GitHub License](https://img.shields.io/github/license/tiann/KernelSU?logo=gnu)](/LICENSE)

## Características

1. `su` e gerenciamento de acesso root baseado em kernel.
2. Sistema de módulos baseado em [metamodules](https://kernelsu.org/pt_BR/guide/metamodule.html): Infraestrutura plugável para modificações systemless.
3. [Perfil do Aplicativo](https://kernelsu.org/pt_BR/guide/app-profile.html): Tranque o poder root em uma gaiola.

## Estado de compatibilidade

O KernelSU oferece suporte oficial a dispositivos Android GKI 2.0 (kernel 5.10+). Kernels mais antigos (4.14+) também são compatíveis, mas será necessário construir o kernel manualmente.

Com isso, WSA, ChromeOS e Android baseado em contêiner são todos suportados.

Atualmente, as arquiteturas `arm64-v8a` e `x86_64` são suportadas.

> [!CAUTION]
> Versões recentes do kernel implementaram uma mudança que quebra a compatibilidade, fazendo com que o KernelSU falhe e potencialmente cause um kernel panic no `x86_64`! Verifique o site para mais informações!

## Uso

 - [Instalação](https://kernelsu.org/pt_BR/guide/installation.html)
 - [Como compilar](https://kernelsu.org/pt_BR/guide/how-to-build.html)
 - [Site oficial](https://kernelsu.org/pt_BR/)

## Tradução

Para contribuir com a tradução do KernelSU ou aprimorar traduções existentes, por favor, use o [Weblate](https://hosted.weblate.org/engage/kernelsu/). PR para a tradução do Manager não são mais aceitas, pois podem entrar em conflito com o Weblate.

## Discussão

- Telegram: [@KernelSU](https://t.me/KernelSU)

## Segurança

Para obter informações sobre como relatar vulnerabilidades de segurança do KernelSU, consulte [SECURITY.md](/SECURITY.md).

## Licença

- Os arquivos no diretório `kernel` são [GPL-2.0-only](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
- Todas as outras partes, exceto o diretório `kernel` são [GPL-3.0-or-later](https://www.gnu.org/licenses/gpl-3.0.html).

## Créditos

- [Kernel-Assisted Superuser](https://git.zx2c4.com/kernel-assisted-superuser/about/): A ideia do KernelSU.
- [Magisk](https://github.com/topjohnwu/Magisk): A poderosa ferramenta root.
- [genuine](https://github.com/brevent/genuine/): Validação de assinatura APK v2.
- [Diamorphine](https://github.com/m0nad/Diamorphine): Algumas habilidades de rootkit.
