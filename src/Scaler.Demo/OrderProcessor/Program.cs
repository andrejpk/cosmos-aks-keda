using Keda.CosmosDb.Scaler.Demo.Shared;
using Azure.Monitor.OpenTelemetry.Exporter;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using OpenTelemetry.Logs;
using OpenTelemetry.Exporter.OpenTelemetryProtocol;
using System.Collections.Generic;
using OpenTelemetry.Resources;
using System.Diagnostics;

namespace Keda.CosmosDb.Scaler.Demo.OrderProcessor;
internal static class Program
{
    static Dictionary<string, object> resourceAttributes = new Dictionary<string, object>
        {
            { "service.name", "OrderProcessor" },
            { "service.instance.id", System.Environment.MachineName }
        };
    static ResourceBuilder resourceBuilder = ResourceBuilder.CreateDefault().AddAttributes(resourceAttributes);

    // Create a new tracer provider builder and add an Azure Monitor trace exporter to the tracer provider builder.
    // It is important to keep the TracerProvider instance active throughout the process lifetime.
    static TracerProvider tracerProvider = OpenTelemetry.Sdk.CreateTracerProviderBuilder()
        // .AddAzureMonitorTraceExporter()
        .AddOtlpExporter()
        .AddSource("Azure.*")
        .AddSource("Keda.CosmosDb.Scaler.Demo.OrderProcessor")
        .SetResourceBuilder(resourceBuilder)
        .Build();

    // Add an Azure Monitor metric exporter to the metrics provider builder.
    // It is important to keep the MetricsProvider instance active throughout the process lifetime.
    static MeterProvider metricsProvider = OpenTelemetry.Sdk.CreateMeterProviderBuilder()
        // .AddAzureMonitorMetricExporter()
        .AddOtlpExporter()
        .AddRuntimeInstrumentation()
        .SetResourceBuilder(resourceBuilder)
        .Build();

    public static ActivitySource activitySource = new ActivitySource("Keda.CosmosDb.Scaler.Demo.OrderProcessor");

    public static void Main(string[] args)
    {
        CreateHostBuilder(args).Build().Run();
    }

    public static IHostBuilder CreateHostBuilder(string[] args) =>
        Host.CreateDefaultBuilder(args)
            .ConfigureLogging(builder =>
                builder.AddOpenTelemetry(options =>
                {
                    // options.AddAzureMonitorLogExporter();
                    options.AddOtlpExporter();
                }
            )
            .AddSimpleConsole(options => options.TimestampFormat = "yyyy-MM-dd HH:mm:ss "))
            .ConfigureServices((hostContext, services) =>
            {
                services.AddHostedService<Worker>();
                services.AddSingleton(CosmosDbConfig.Create(hostContext.Configuration));
            });
}

