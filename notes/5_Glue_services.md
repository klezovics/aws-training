# Glue service list
- SQS -> queue/pull, buffering, decoupling, work distribution. One message → one consumer.
- SNS -> broadcast / fan-out. No storage.
- EventBridge ->  content-based routing, 20+ target types, archive + replay
- Step functions -> schedulers and multi-step workflows
- Kinesis/Firehose -> event stream
- Amazon MQ -> Managed RabbitMQ/ActiveMQ