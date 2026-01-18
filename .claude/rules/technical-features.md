# 技術的な特徴

## 構造化ログ（SemanticLogger）

- 全環境でJSON形式出力
- リクエストごとに自動付与される `trace_id` で横断的な追跡が可能
- エラーレスポンスに `trace_id` を含めることでログとの紐付けが可能

## グローバルエラーハンドリング

- 統一されたエラーレスポンス形式（JSON）
- トレースID連携
- カスタムエラー対応: ビジネスロジック固有のエラーは `DomainError` を継承

エラーレスポンス例:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Couldn't find User with 'id'=999",
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf"
  }
}
```

## API仕様書（RSwag）

- RSpecのリクエストスペックから自動生成
- Swagger UI: <http://localhost:3000/api-docs>
- 定義ファイル: `swagger/v1/swagger.yaml`
