using System;
using System.Runtime.CompilerServices;
using Azure.Monitor.OpenTelemetry.Exporter;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

[assembly: InternalsVisibleTo("DynamicProxyGenAssembly2")] // Required by mock generator.
[assembly: InternalsVisibleTo("Keda.CosmosDb.Scaler.Tests")]

namespace Keda.CosmosDb.Scaler
{
    internal static class Program
    {
        // Create a new tracer provider builder and add an Azure Monitor trace exporter to the tracer provider builder.
        // It is important to keep the TracerProvider instance active throughout the process lifetime.
        static TracerProvider tracerProvider = OpenTelemetry.Sdk.CreateTracerProviderBuilder()
            .AddAzureMonitorTraceExporter()
            .AddSource("Azure.*")
            .Build();

        // Add an Azure Monitor metric exporter to the metrics provider builder.
        // It is important to keep the MetricsProvider instance active throughout the process lifetime.
        static MeterProvider metricsProvider = OpenTelemetry.Sdk.CreateMeterProviderBuilder()
            .AddAzureMonitorMetricExporter()
            .Build();

        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        // Additional configuration is required to successfully run gRPC on macOS.
        // For instructions on how to configure Kestrel and gRPC clients on macOS, visit https://go.microsoft.com/fwlink/?linkid=2099682
        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                // Create a new logger factory.
                // It is important to keep the LoggerFactory instance active throughout the process lifetime.            
                .ConfigureLogging(builder => builder.AddOpenTelemetry(options =>
                {
                    options.AddAzureMonitorLogExporter();
                })
                .AddSimpleConsole(options => options.TimestampFormat = "yyyy-MM-dd HH:mm:ss "))
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.ConfigureKestrel(kestrelServerOptions =>
                    {
                        // Setup a HTTP/2 endpoint without TLS.
                        kestrelServerOptions.ListenAnyIP(port: 4050, listOptions => listOptions.Protocols = HttpProtocols.Http2);
                    });

                    webBuilder.UseStartup<Startup>();
                });
    }
}
