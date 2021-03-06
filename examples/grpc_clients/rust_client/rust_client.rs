extern crate grpc;
extern crate protobuf;
extern crate crawler_rust_proto;
extern crate protoconf_service_rust_proto;

use crawler_rust_proto::*;
use protoconf_service_rust_proto::*;
use protobuf::stream::CodedInputStream;
use protobuf::Message;
use protobuf::text_format;

fn main() {
    let client = ProtoconfServiceClient::new_plain("::1", 4300, Default::default()).unwrap();
    let mut req = ConfigSubscriptionRequest::new();
    req.set_path("crawler/text_crawler".to_owned());

    let stream = client.subscribe_for_config(grpc::RequestOptions::new(), req);
    let mut first_read = true;
    match stream.wait() {
        Err(e) => panic!("{:?}", e),
        Ok((_, stream)) => {
            for stream_item in stream {
                let config_update = stream_item.unwrap();
                let any_value = config_update.get_value().get_value();
                let mut bytes = CodedInputStream::from_bytes(any_value);
                
                let mut crawler_service = CrawlerService::new();
                match crawler_service.merge_from(&mut bytes) {
                    Err(e) => panic!("{:?}", e),
                    Ok(_) => {
                        if first_read {
                            first_read = false;
                            println!("Config initial value: {}", text_format::print_to_string(&crawler_service));
                        } else {
                            println!("Config changed, new value: {}", text_format::print_to_string(&crawler_service));
                        }
                    }

                }
            }
        }
    }
}
