# MobileUp Network Kit

#### MUNNetworkService<Target: MUNAPITarget>

Актор, выполняющий сетевые запросы с использованием Moya. Является generic-типом, где параметр Target должен соответствовать протоколу MUNAPITarget. Это позволяет использовать MUNNetworkService с любым API, определенным через перечисление, реализующее MUNAPITarget. Поддерживает автоматическое обновление токена при получении ошибок авторизации.

**Инициализация**:
```swift
public init(apiProvider: MoyaProvider<Target>, tokenRefreshProvider: MUNAccessTokenProvider)
```
- apiProvider — Экземпляр MoyaProvider для выполнения запросов. Где параметр Target должен соответствовать протоколу MUNAPITarget.
- tokenRefreshProvider — Провайдер, отвечающий за предоставление и обновление токена авторизации.

**Основные методы**:
- `executeRequest<T: Decodable & Sendable>(target: Target, isTokenRefreshed: Bool) async throws -> T`  Выполняет запрос и возвращает декодированный объект типа T.
- `executeRequest(target: Target, isTokenRefreshed: Bool) async throws` Выполняет запрос без возврата данных.
- `setTokenRefreshFailureHandler(_ action: @escaping () async -> Void)` Метод для установки обработчика для случаев, когда обновление токена не удалось. Обработчик выполняется в случае, если метод refreshToken в TokenProvider выбросил ошибку.

#### MUNAPITarget 
 Протокол расширяет TargetType и AccessTokenAuthorizable, добавляя дополнительные свойства для управления параметрами запроса и настройки авторизации:
- parameters: [String: Any] Используется для добавления параметров в запрос. 
- isAccessTokenRequired: Bool Указывает, требуется ли токен авторизации для данного запроса.
- isRefreshTokenRequest: Bool Указывает, является ли запрос запросом для обновления токена. MUNNetworkService использует isRefreshTokenRequest, чтобы избежать бесконечных циклов при обновлении токена.

#### MUNAccessTokenProvider
Протокол определяет интерфейс для предоставления и обновления токена авторизации. Он используется MUNNetworkService и MUNAccessTokenPlugin для добавления токена в HTTP-запросы и обработки случаев, когда токен становится недействительным.
 Свойства и методы:
`accessToken: String?` Токен, который используется для аутентификации в запросах.
`refreshToken()` Метод, который выполняет обновление токена.

#### MUNAccessTokenPlugin
Структура представляет собой реализацию протокола PluginType из библиотеки Moya, которая модифицирует запросы перед их отправкой. Основная задача плагина — добавлять заголовок Authorization с токеном, полученным от MUNAccessTokenProvider, для запросов, где это необходимо.

#### MUNLoggerPlugin
Актор, который оборачивает функциональность NetworkLoggerPlugin из библиотеки Moya, предоставляя логирование сетевых запросов и ответов. 

Пример создания networkService:
```swift
private let tokenProvider = TokenProvider()

private let provider = MoyaProvider<ExampleAPITarget>(
    plugins: [
        MUNAccessTokenPlugin(accessTokenProvider: tokenProvider),
        MockAuthPlugin()
    ]
)

private let networkService = MUNNetworkService(apiProvider: provider, tokenRefreshProvider: tokenProvider)

await networkService.setTokenRefreshFailureHandler { print("🧨 Token refresh failed handler called") }
```

#### Работа с моковыми данными
Для управления подменой реального ответа от сервера на мок необходимо настроить поведение stubClosure MoyaProvider. 
**Пример настройки:**
```swift
let apiProvider = MoyaProvider<ExampleApi>(
    stubClosure: Environments.isRelease ? MoyaProvider.neverStub : MoyaProvider.delayedStub(1)
)
```
Для использования реализуем протокол MUNMockableAPITarget, добавляем моковые данные в json-формате в Resources/Mock. Для переключения мок/реальный запрос используется свойство isMockEnabled.
**Пример использования:**

```swift
extension ExampleApi: MUNMockableAPITarget {
    var isMockEnabled: Bool { getIsMockEnabled() }
    
    func getMockFileName() -> String? {
        switch self {
        case .testItems:
            return "MockTempTokenModel"
        }
    }
    
    private func getIsMockEnabled() -> Bool {
        switch self {
        case .testItems:
            return true
        }
    }
}
```
