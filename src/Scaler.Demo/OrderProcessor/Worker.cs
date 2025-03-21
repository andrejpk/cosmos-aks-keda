using System;
using System.Collections.Generic;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Keda.CosmosDb.Scaler.Demo.Shared;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Azure.Identity;
using System.Diagnostics;

using Container = Microsoft.Azure.Cosmos.Container;

namespace Keda.CosmosDb.Scaler.Demo.OrderProcessor
{
    internal sealed class Worker : BackgroundService
    {
        private readonly CosmosDbConfig _cosmosDbConfig;
        private readonly ILogger<Worker> _logger;

        private ChangeFeedProcessor _processor;


        public Worker(CosmosDbConfig cosmosDbConfig, ILogger<Worker> logger)
        {
            _cosmosDbConfig = cosmosDbConfig ?? throw new ArgumentNullException(nameof(cosmosDbConfig));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        public override async Task StartAsync(CancellationToken cancellationToken)
        {
            Database leaseDatabase;


            if (string.IsNullOrEmpty(_cosmosDbConfig.LeaseConnection))
            {
                var credential = new DefaultAzureCredential();

                leaseDatabase = new Microsoft.Azure.Cosmos.CosmosClient(_cosmosDbConfig.LeaseEndpoint, credential)
                    .GetDatabase(_cosmosDbConfig.LeaseDatabaseId);
            }
            else
            {
                leaseDatabase = new Microsoft.Azure.Cosmos.CosmosClient(_cosmosDbConfig.LeaseConnection)
                    .GetDatabase(_cosmosDbConfig.LeaseDatabaseId);
            }

            Container leaseContainer = leaseDatabase.GetContainer(_cosmosDbConfig.LeaseContainerId);

           

            // Change feed processor instance name should be unique for each container application.
            string instanceName = $"Instance-{Dns.GetHostName()}";

            CosmosClient cosmosClient;

            if (string.IsNullOrEmpty(_cosmosDbConfig.Connection))
            {
                var credential = new DefaultAzureCredential();

                cosmosClient = new Microsoft.Azure.Cosmos.CosmosClient(_cosmosDbConfig.Endpoint, credential);
            }
            else
            {
                cosmosClient = new Microsoft.Azure.Cosmos.CosmosClient(_cosmosDbConfig.Connection);
            }

            Container monitoredContainer = cosmosClient.GetContainer(_cosmosDbConfig.DatabaseId, _cosmosDbConfig.ContainerId);


            _processor = monitoredContainer
                   .GetChangeFeedProcessorBuilder<Order>("SalesOrderChangeFeed", ProcessOrdersAsync)
                       .WithInstanceName(instanceName)
                       .WithMaxItems(1000)
                       .WithLeaseContainer(leaseContainer)
                       .Build();

            

            await _processor.StartAsync();
            _logger.LogInformation($"Started change feed processor instance {instanceName}");
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            await _processor.StopAsync();
            _logger.LogInformation("Stopped change feed processor");

            await base.StopAsync(cancellationToken);
        }

        protected override Task ExecuteAsync(CancellationToken stoppingToken)
        {
            return Task.CompletedTask;
        }

        private async Task ProcessOrdersAsync(IReadOnlyCollection<Order> orders, CancellationToken cancellationToken)
        {            
            _logger.LogInformation($"{orders.Count} order(s) received");

            foreach (Order order in orders)
            {
                using var proAct = Program.activitySource.StartActivity("ProcessOrdersAsync", ActivityKind.Server);
                _logger.LogInformation($"Processing order {order.Id} - {order.Amount} unit(s) of {order.Article} bought by {order.Customer.FirstName} {order.Customer.LastName}");

                // Add delay to fake the time consumed in processing the order.
                await Task.Delay(TimeSpan.FromSeconds(2), cancellationToken);
                _logger.LogInformation($"Order {order.Id} processed");
            }
        }
    }
}
