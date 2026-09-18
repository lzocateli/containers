using Azure.Messaging.ServiceBus;

string? queue = null;
string? topic = null;
string? subscription = null;

for (var i = 0; i < args.Length; i++)
{
    switch (args[i])
    {
        case "--queue":
            queue = args[++i];
            break;
        case "--topic":
            topic = args[++i];
            break;
        case "--subscription":
            subscription = args[++i];
            break;
        default:
            Console.Error.WriteLine($"Unknown argument: {args[i]}");
            return 2;
    }
}

if (queue is null && (topic is null || subscription is null))
{
    Console.Error.WriteLine("Usage: sb-smoke --queue <name> | --topic <name> --subscription <name>");
    return 2;
}

var emulatorHost = Environment.GetEnvironmentVariable("EMULATOR_HOST") ?? "localhost";
var httpPort = Environment.GetEnvironmentVariable("EMULATOR_HTTP_PORT") ?? "5300";
var healthUrl = $"http://{emulatorHost}:{httpPort}/health";

using (var httpClient = new HttpClient())
{
    Console.WriteLine($"Waiting for {healthUrl} to report healthy...");
    var deadline = DateTime.UtcNow.AddSeconds(60);
    var healthy = false;
    while (DateTime.UtcNow < deadline)
    {
        try
        {
            var response = await httpClient.GetAsync(healthUrl);
            if (response.IsSuccessStatusCode)
            {
                healthy = true;
                break;
            }
        }
        catch (HttpRequestException)
        {
            // Not ready yet; keep polling.
        }

        await Task.Delay(TimeSpan.FromSeconds(2));
    }

    if (!healthy)
    {
        Console.Error.WriteLine("Emulator did not become healthy in time.");
        return 1;
    }
}

// AmqpTcp is required: the emulator does not support AMQP over WebSockets.
var clientOptions = new ServiceBusClientOptions { TransportType = ServiceBusTransportType.AmqpTcp };
var connectionString =
    $"Endpoint=sb://{emulatorHost};SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;";

const string messageBody = "sb-smoke-ping";

await using var client = new ServiceBusClient(connectionString, clientOptions);

try
{
    if (queue is not null)
    {
        await using var sender = client.CreateSender(queue);
        await sender.SendMessageAsync(new ServiceBusMessage(messageBody));

        await using var receiver = client.CreateReceiver(queue);
        var received = await receiver.ReceiveMessageAsync(TimeSpan.FromSeconds(15));
        return Validate(received, messageBody, $"queue '{queue}'");
    }
    else
    {
        await using var sender = client.CreateSender(topic);
        await sender.SendMessageAsync(new ServiceBusMessage(messageBody));

        await using var receiver = client.CreateReceiver(topic, subscription);
        var received = await receiver.ReceiveMessageAsync(TimeSpan.FromSeconds(15));
        return Validate(received, messageBody, $"topic '{topic}' / subscription '{subscription}'");
    }
}
catch (Exception ex) when (ex is ServiceBusException or TimeoutException)
{
    Console.Error.WriteLine($"Smoke test failed: {ex.Message}");
    return 1;
}

static int Validate(ServiceBusReceivedMessage? received, string expectedBody, string entityDescription)
{
    if (received is null)
    {
        Console.Error.WriteLine($"No message received from {entityDescription} within the timeout.");
        return 1;
    }

    var body = received.Body.ToString();
    if (body != expectedBody)
    {
        Console.Error.WriteLine($"Unexpected message body from {entityDescription}: '{body}'");
        return 1;
    }

    Console.WriteLine($"Round-trip succeeded on {entityDescription}.");
    return 0;
}
