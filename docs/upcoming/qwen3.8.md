# Qwen3.8 추가 준비 (다음 주 작업용)

> 작성일: 2026-08-03 · 상태: 오픈웨이트 미공개 — 본 문서는 준비용이며 본 표에는 아직 반영하지 않음

## 확인된 사실 (2026-08-03 기준)

- 2026-07-19 발표: **2.4T 파라미터**, 네이티브 멀티모달, "오픈웨이트 곧 공개" 예고 (날짜·라이선스 미정)
- 자사 주장 "Fable 5 다음으로 강력" — **벤치마크·모델 카드·아키텍처 미공개**, 검증 불가
- 현재는 Qwen3.8-Max-Preview로 Alibaba Token Plan·Qoder·QoderWork에서만 사용 가능 (자체 배포 불가)
- 소형 라인업(27B 등): 웹에서 미확인. 3.5/3.6 패턴(27B·35B-A3B 동시 출시)상 27B 동반 출시 가능성 높음 — 사용자 제보로는 27B 존재

## 공개되면 확인할 것 (체크리스트)

- [ ] HF 공식 리포 URL·라이선스 (Apache-2.0 여부)
- [ ] 라인업: 2.4T 활성 파라미터 수 / 27B dense 여부 / 중간 MoE 유무
- [ ] 공식 체크포인트 포맷·파일 크기 (FP8? MXFP4? BF16?)
- [ ] 공식 배포 가이드의 권장 GPU 구성 (SGLang/vLLM 버전 요구 포함)
- [ ] 공식 벤치마크 표 (SWE-bench V/Pro, GPQA, LiveCodeBench) — 3.6-27B와 비교
- [ ] 멀티모달 입력의 서빙 메모리 오버헤드

## 사전 적재 계산 (파라미터 기준 추정 — 공개 후 실측 파일 크기로 교체)

가이드가 다루는 전 구성 기준. ◎ 여유 / ○ 가능 / △ 조건부 / ✗ 불가.

### Qwen3.8 2.4T (활성 파라미터 미공개)

| 구성 | 명목 VRAM | 4bit ≈1.2TB | FP8 ≈2.4TB |
|---|---:|---|---|
| 2×2080 Ti · 2×4090 | 22~48GB | ✗ | ✗ |
| A100 40/80GB (2·4·8장) | 80~640GB | ✗ | ✗ |
| 2×·4×·8×H100 | 160~640GB | ✗ | ✗ |
| 16×H100 | 1.28TB | △ **경계 미달 가능성** — 가중치 1.2TB면 runtime 공간 부족, 실측 파일 크기 확인 필수 | ✗ |
| 8×MI300X | 1.54TB | △ 용량은 가능 — FP4/INT4 ROCm 경로 확인 필요 | ✗ |
| 8×B300 | 2.30TB | ◎ | △ 경계 미달(2.4TB > 2.30TB) — 16×H200/멀티노드 |

공개 포맷이 K3처럼 MXFP4(≈4.3bit/param ≈ 1.3TB)면 16×H100은 사실상 탈락, MI300X는 dequant 경로 검증 전 보류 — B300이 기본 타깃.

### Qwen3.8-27B (가정: 3.6-27B 유사 dense — 공개 후 확정)

| 구성 | 예상 시작점 |
|---|---|
| 2×2080 Ti | GGUF Q4_K_M ≈17GB — 3.6-27B 행 교체 후보 |
| 2×4090 | FP8 ≈31GB TP=2 또는 Q4 GPU당 1 replica |
| 2×A100 40GB / 80GB | BF16 ≈56GB (A100은 FP8 미지원) |
| 2×H100 | FP8 GPU당 1 replica |
| 8×H100 | FP8 × 8 replicas — 고동시성 소형 서빙 행 교체 후보 |
| MI300X/B300 | 단일 GPU 적재 — 별도 행 불필요, 벤치 우위 시에만 교체 |

35B-A3B급 MoE가 같이 나오면 4090 처리량 행·4×H100 agent loop 행도 교체 후보.

## 공개 시 수정할 파일 (순서대로)

1. `docs/model-options.md` — 가중치 표 행 + "Qwen3.8" 섹션 (Qwen3.6 섹션 아래)
2. `README.md` 구성별 표 — 27B가 3.6-27B 대비 우위면 2080Ti/4090/2×H100/8×H100 소형 행 교체, 2.4T는 적재 가능 구성에만
3. `docs/hardware-matrix.md` — 해당 구성 결정표
4. `docs/best-pick/*` — 2.4T 벤치가 Kimi K3·GLM-5.2를 실제로 넘으면 픽 재평가 (자사 주장만으로는 변경하지 않음)
5. `docs/sources.md` — 출처 (자사 보고 벤치는 참고치 표기)
6. 이 문서 삭제

## 출처

- [the-decoder — Qwen 3.8 발표, "second only to Fable 5" 주장](https://the-decoder.com/alibabas-qwen-takes-on-kimi-k3-with-open-weight-qwen-3-8-says-model-is-second-only-to-fable-5/)
- [MLQ — 2.4T 발표 정리](https://mlq.ai/news/alibaba-launches-qwen-38-with-24-trillion-parameters-claims-near-frontier-performance/)
- [techsy — 벤치마크 부재 지적](https://techsy.io/en/blog/qwen-3-8)
- [Qwen 공식 X 발표](https://x.com/Alibaba_Qwen/status/2078759124914098291)
