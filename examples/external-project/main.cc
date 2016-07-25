#include "tensorflow/core/public/session.h"
#include "tensorflow/core/platform/env.h"


int main(int argc, char** argv) {
    namespace tf = tensorflow;

    tf::Session* session;
    tf::Status status = tf::NewSession(tf::SessionOptions(), &session);
    if (!status.ok()) {
        std::cout << status.ToString() << std::endl;
        return 1;
    }

    tf::GraphDef graph_def;
    status = ReadBinaryProto(tf::Env::Default(), "graph.pb", &graph_def);
    if (!status.ok()) {
        std::cout << status.ToString() << std::endl;
        return 1;
    }

    status = session->Create(graph_def);
    if (!status.ok()) {
        std::cout << status.ToString() << std::endl;
        return 1;
    }

    tf::Tensor x(tf::DT_FLOAT, tf::TensorShape()), y(tf::DT_FLOAT, tf::TensorShape());
    x.scalar<float>()() = 23.0;
    y.scalar<float>()() = 19.0;

    std::vector<std::pair<tf::string, tf::Tensor>> input_tensors = {{"x", x}, {"y", y}};
    std::vector<tf::Tensor> output_tensors;

    status = session->Run(input_tensors, {"z"}, {}, &output_tensors);
    if (!status.ok()) {
        std::cout << status.ToString() << std::endl;
        return 1;
    }
    
    tf::Tensor output = output_tensors[0];
    std::cout << "Success: " << output.scalar<float>() << "!" << std::endl;
    session->Close();
    return 0;
}
