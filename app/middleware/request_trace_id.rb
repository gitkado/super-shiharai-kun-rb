# frozen_string_literal: true

# リクエストごとにトレースIDを設定し、SemanticLoggerのnamed tagsに追加するミドルウェア
# X-Trace-Idヘッダーがある場合はそれを使用し、ない場合は新規生成する
class RequestTraceId
  TRACE_ID_HEADER = "X-Trace-Id"

  def initialize(app)
    @app = app
  end

  def call(env)
    # ヘッダーからトレースIDを取得、なければ生成
    trace_id = extract_trace_id(env) || generate_trace_id

    # SemanticLoggerのnamed tagsとしてトレースIDを設定
    # これによりすべてのログにtrace_idが自動的に含まれる
    SemanticLogger.named_tagged(trace_id: trace_id) do
      # レスポンスヘッダーにトレースIDを追加
      status, headers, body = @app.call(env)
      headers[TRACE_ID_HEADER] = trace_id
      [ status, headers, body ]
    end
  end

  private

  def extract_trace_id(env)
    # Rackの環境変数はHTTP_プレフィックスとアンダースコアに変換される
    env["HTTP_X_TRACE_ID"]
  end

  def generate_trace_id
    SecureRandom.uuid
  end
end
