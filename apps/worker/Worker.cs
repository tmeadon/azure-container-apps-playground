using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Azure.Storage.Queues;
using Azure.Storage.Queues.Models;
using Dapr.Client;

namespace worker
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly IConfiguration _configuration;
        private readonly QueueClient _queueClient;
        private readonly DaprClient _daprClient;


        public Worker(ILogger<Worker> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            var storageConnection = _configuration.GetValue<string>("STORAGE_CONNECTION");
            var queueName = _configuration.GetValue<string>("QUEUE_NAME");

            if (!string.IsNullOrEmpty(storageConnection) && !string.IsNullOrEmpty(queueName))
            {
                _queueClient = new QueueClient(storageConnection, queueName);
            }

            _daprClient = new DaprClientBuilder().Build();
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("Worker running at: {time}", DateTimeOffset.Now);

                var message = await _queueClient.ReceiveMessageAsync(null, stoppingToken);

                if (message.Value != null)
                {
                    _logger.LogInformation($"Message received with body: {message.Value.Body}");

                    try
                    {
                        var bodyList = message.Value.Body.ToObjectFromJson<List<string>>();
                        var currentList = await _daprClient.GetStateAsync<List<string>>("statestore", "names", null, null, stoppingToken);
                        currentList.AddRange(bodyList);
                        await _daprClient.SaveStateAsync<List<string>>("statestore", "names", currentList);
                        await _queueClient.DeleteMessageAsync(message.Value.MessageId, message.Value.PopReceipt, stoppingToken);
                    }
                    catch (Exception e) 
                    {
                        _logger.LogError(e, "Unable to process message");

                        if (message.Value.DequeueCount > 5)
                        {
                            await _queueClient.DeleteMessageAsync(message.Value.MessageId, message.Value.PopReceipt, stoppingToken);
                        }
                    }
                    
                }

                await Task.Delay(5000);
            }
        }
    }
}
