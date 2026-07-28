---
description: "Use ao criar ou alterar README de uma imagem de container. Define badges, contrato da imagem, execução, configuração, persistência, segurança, validação e release."
applyTo: ["**/README.md", "**/readme.md"]
---

# README de imagem

- Use `.github/templates/container-README.template.md` como estrutura canônica.
- O arquivo novo deve se chamar `README.md`, preservando maiúsculas para funcionar em Linux e no workflow.
- Preserve o cabeçalho SPDX do template para identificar a licença do documento sem atribuí-la aos componentes da imagem.
- Comece com badges de `img.shields.io/badge` para imagem, versão, base, plataformas, licença do conteúdo original do repositório e status de build. Não apresente `MIT` como licença de toda a imagem.
- Documente o contrato observado pelo consumidor; detalhes de manutenção ficam nas seções Build, Validação e Publicação.
- Use uma única seção para cada informação. Referencie seções existentes em vez de repetir comandos ou tabelas.
- Diferencie recursos instalados de recursos habilitados em runtime.
- Declare tags imutáveis, imagem base, arquiteturas, usuário, portas, volumes, health check, entrypoint e política de atualização.
- Marque variáveis como obrigatórias, opcionais ou secretas; nunca publique valores reais.
- Inclua exemplos mínimos de Docker e Compose que possam ser executados após substituir placeholders.
- Explique bootstrap, migração, persistência, backup, upgrade e rollback quando aplicáveis.
- Registre limitações conhecidas, compatibilidade e troubleshooting orientado por sintomas.
- Inclua fontes, licenças e atribuições da imagem base e das dependências distribuídas.
- Declare que a licença MIT cobre somente o conteúdo original do repositório e referencie `LICENSING.md` por URL absoluta, compatível com a descrição no Docker Hub.
- Preserve avisos upstream e não afirme que a licença do repositório relicencia componentes de terceiros.
- Mantenha a descrição compatível com Markdown do Docker Hub; evite HTML dependente do GitHub.
