# CS Daily Auto-learner

매일 Claude Code가 Notion DB에 CS 학습 페이지를 자동 생성합니다.
프론트엔드 4년차 yj.kim 의 학습 루틴 자동화용.

## 디렉토리

```
cs-daily/
├── .env                # 토큰 (직접 채워야 함, .env.example 참조)
├── .mcp.json           # Notion MCP 설정
├── curriculum.json     # 8 카테고리 × 기초/응용 약 175개 주제 (마스터 데이터)
├── prompts/
│   ├── daily.md       # 평일 프롬프트
│   └── weekly.md      # 주말 프롬프트
├── samples/                    # 시범으로 사전 생성된 페이지 본문 예시
├── scripts/
│   ├── run-daily.sh / .bat
│   ├── run-weekly.sh / .bat
│   ├── register-task.ps1       # Windows 작업 스케줄러 자동 등록
│   ├── verify-notion.ps1       # Notion DB 스키마 점검 (Windows)
│   └── verify-notion.sh        # Notion DB 스키마 점검 (Mac/Linux)
└── logs/              # 실행 로그
```

---

## 최초 셋업 (1회만)

### 1. 의존성 확인

```bash
node -v          # v18 이상 필요 (Notion MCP가 npx 로 실행됨)
claude --version # Claude Code 설치 확인. 없으면: npm i -g @anthropic-ai/claude-code
```

### 2. `.env` 작성

`.env.example` 을 `.env` 로 복사하고 값 채우기:

```
NOTION_TOKEN=ntn_xxxxxxxxxxxxxxxxxxxxxx
NOTION_DB_ID=70d3b097f7a1430e87d5e96c2abc17d8
```

- Notion 토큰 발급: <https://www.notion.so/profile/integrations>
- Integration 을 만든 뒤 **꼭 대상 DB 페이지에서 "Connect" 해주기** (안 하면 403).

### 3. Claude Code 로그인 (구독 사용 모드)

```bash
claude /login
```

Pro/Max 구독으로 로그인하면 자동 호출이 구독 한도에서 차감됩니다.

### 4. (선택) DB 스키마 사전 점검

`.env` 의 토큰과 DB ID 가 정상인지, property 8 개가 잘 등록됐는지 먼저 확인:

```powershell
# Windows
.\scripts\verify-notion.ps1

# Mac/Linux (jq 필요)
bash scripts/verify-notion.sh
```

### 5. 첫 실행으로 동작 확인

```bash
# Mac/Linux
bash scripts/run-daily.sh

# Windows (cmd)
scripts\run-daily.bat
```

성공 시: Notion DB 에 오늘 자 페이지 2개가 생기고 `logs/daily_*.log` 에 실행 로그가 남습니다.
실패 시: `logs/` 의 최신 .log 파일을 먼저 확인하세요. `samples/` 폴더에 시범 페이지 본문 두 개가 들어있으니 어떤 결과물을 기대하면 되는지 미리 확인할 수 있습니다.

---

## 스케줄링

### Windows 작업 스케줄러 (사용자 권장 환경)

가장 중요한 트리거 2개:

| 트리거 | 동작 |
|---|---|
| **매일 오전 7시** | `scripts\run-daily.bat` |
| **시스템 시�