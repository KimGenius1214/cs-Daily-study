# CS Daily 자동화 - Claude Code 핸드오프 문서

이 문서는 Claude.ai 웹 대화에서 진행된 설계 결정사항을 Claude Code로 옮기기 위한 문서입니다.
Claude Code 첫 실행 시 이 문서를 읽혀서 컨텍스트를 이어가세요.

## 사용자 컨텍스트

- 프론트엔드 4년차 개발자
- 회사: Ableunion, 프로젝트: `paysable-front-app-v2` (결제 관련 Next.js/TypeScript)
- CS 기초가 약하다고 느끼고 있어 매일 자동 학습 시스템을 원함
- GitHub username: `KimGenius1214`
- Windows 환경 사용 추정

## 목표

매일 자동으로 Notion DB에 CS 학습 페이지를 생성한다. 평일엔 2주제(기초+응용), 주말엔 주간 요약.
출퇴근/짬짬이 시간에 Notion에서 열어보며 학습.

## 핵심 결정 사항

### 1. 학습 비중
프론트 실무 직결 우선:
- **고비중** (주 2회): 네트워크/브라우저, 프론트엔드 심화, 보안/인증
- **중비중**: 자료구조/알고리즘, AI/ML/LLM, 시스템 설계
- **저비중**: 운영체제, 데이터베이스

### 2. 카테고리 8개
- 자료구조/알고리즘
- 네트워크/브라우저
- 운영체제/시스템
- 데이터베이스
- 보안/인증
- AI/ML/LLM
- 시스템 설계/아키텍처
- 프론트엔드 심화

### 3. 하루 분량
- 평일: 2주제 (기초 1 + 응용 1)
- 주말: 그 주 학습 내용 요약 페이지만

### 4. Notion DB 스펙
- **DB ID**: `70d3b097f7a1430e87d5e96c2abc17d8`
- **Integration**: 이미 connect 완료
- **Properties 8개** (모두 등록 완료):
  - Title (Title)
  - Category (Select, 8개 이모지 포함 옵션)
  - Level (Select: 기초/응용/주간요약)
  - Date (Date)
  - Day (Select: 월~일)
  - Status (Select: 신규/읽음/복습필요/완료)
  - Tags (Multi-select)
  - 실무연결도 (Select: ⭐/⭐⭐/⭐⭐⭐)

### 5. 복습 시스템
- **수동만** (Status 직접 토글)
- 자동화는 페이지 생성만 담당

### 6. 실행 환경 (최종)
- GitHub Actions 안 씀 (Anthropic API 키 별도 발급 비용 부담)
- **Claude Code 구독을 그대로 활용** (Pro/Max에 포함)
- 본인 PC를 24시간 켜두고 Windows 작업 스케줄러로 매일 실행

## 파일 구조 (이미 생성됨)

```
cs-daily/
├── .env                # NOTION_TOKEN 필요
├── .env.example
├── .mcp.json           # Notion MCP 등록
├── .gitignore
├── README.md
├── curriculum.json     # 8 카테고리 × 기초/응용 약 175개 주제
├── progress.json       # 진행 상태 (자동 갱신)
├── prompts/
│   ├── daily.md       # 평일 프롬프트 - 주제 선정 로직 + 페이지 생성 지시
│   └── weekly.md      # 주말 프롬프트 - 주간 요약 생성 지시
├── scripts/
│   ├── run-daily.sh / .bat   # 평일 (월~금)
│   └── run-weekly.sh / .bat  # 주말 (토~일)
└── logs/
```

## 동작 방식

1. 작업 스케줄러가 매일 아침 7시 `run-daily.bat` 실행
2. `.bat`이 오늘 이미 실행됐는지 lock 파일로 체크 (`logs/.lastrun_YYYYMMDD.lock`)
3. `claude -p prompts/daily.md` 호출 (Notion MCP 활성)
4. Claude가:
   - `curriculum.json`의 `weekly_rotation`에서 오늘 요일 카테고리 2개 추출
   - `progress.json`에서 미학습 주제 골라내기
   - 각 주제별로 LLM이 페이지 본문 생성 (9개 섹션 구조)
   - Notion API로 페이지 생성
   - `progress.json` 업데이트
5. 토·일에는 `run-weekly.bat`이 대신 실행되어 주간 요약 페이지 생성

## 페이지 본문 구조 (9개 섹션)

각 학습 페이지는 다음 구조로 작성:
1. 🎯 핵심 한 줄
2. 📖 개념 설명
3. ⚙️ 동작 원리
4. 💻 코드 예제 (TypeScript)
5. 🏢 실무 사용 사례 (paysable/일반 프론트 맥락)
6. ⚠️ 주의점 / 흔한 실수
7. 🤔 심화 질문 3개 (면접형/응용형/트러블슈팅형)
8. 🔗 관련 주제

## 사용자가 직접 해야 할 일

- [ ] `cs-daily.tar.gz` 풀기
- [ ] `.env`에 `NOTION_TOKEN` 작성
- [ ] `claude --version`으로 Claude Code 설치 확인
- [ ] 수동 실행 테스트 (`scripts\run-daily.bat`)
- [ ] Windows 절전 모드 OFF 설정
- [ ] 작업 스케줄러 등록 (트리거 2개: 매일 7시 + 시작 시 5분 지연)

## 알려진 이슈 / 주의점

- **첫 1~2주는 결과 품질 모니터링 필요** - 프롬프트 튜닝 여지가 큼
- **PC 꺼져있는 동안은 누락됨** - 다음 부팅 시 그날 분만 자동 재개
- **Claude Code 인증 만료 가능성** - 가끔 `claude login` 재실행 필요할 수 있음
- **JSON parse 에러 가능성** - LLM이 코드펜스 포함하면 깨질 수 있음 (현재 정제 로직 있음)

## 향후 개선 아이디어 (선택)

- 실패 시 Slack/이메일 알림
- progress.json을 GitHub repo로 백업 (manual push)
- 카테고리 비중 조정 (curriculum.json의 weekly_rotation 수정)
- 본문 길이/깊이 튜닝 (prompts/daily.md의 "작성 품질 기준" 부분)

## Claude Code 첫 실행 시 추천 명령

```bash
cd cs-daily
claude
> 이 디렉토리의 HANDOFF.md, README.md, curriculum.json을 읽고 현재 상태 파악해줘.
> 그다음 .env가 있는지, scripts/run-daily.bat이 잘 실행될 수 있는지 점검해줘.
```
