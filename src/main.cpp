/*
 * OBJ Sequence to Alembic Cache Converter
 * 
 * Author: Jaewon Song
 * Company: Dexter Studios
 * Position: R&D Director
 * 
 * Description: Converts OBJ sequence files to a single Alembic cache file
 */

#include <iostream>
#include <filesystem>
#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <chrono>
#include <regex>

#include <Alembic/AbcGeom/All.h>
#include <Alembic/AbcCoreOgawa/All.h>

namespace fs = std::filesystem;
using namespace Alembic::AbcGeom;

struct Vertex {
    float x, y, z;
    Vertex(float x = 0, float y = 0, float z = 0) : x(x), y(y), z(z) {}
};

struct Face {
    std::vector<int> vertices;
};

struct ObjMesh {
    std::vector<Vertex> vertices;
    std::vector<Face> faces;
    std::string filename;
    int frameNumber;
    
    void clear() {
        vertices.clear();
        faces.clear();
    }
};

class ObjParser {
public:
    static bool parseObjFile(const std::string& filename, ObjMesh& mesh) {
        std::ifstream file(filename);
        if (!file.is_open()) {
            std::cerr << "Error: Cannot open file " << filename << std::endl;
            return false;
        }
        
        mesh.clear();
        mesh.filename = filename;
        
        std::string line;
        while (std::getline(file, line)) {
            std::istringstream iss(line);
            std::string prefix;
            iss >> prefix;
            
            if (prefix == "v") {
                float x, y, z;
                iss >> x >> y >> z;
                mesh.vertices.emplace_back(x, y, z);
            }
            else if (prefix == "f") {
                Face face;
                std::string vertex;
                while (iss >> vertex) {
                    // Handle vertex/texture/normal format (e.g., "1/1/1" or "1//1" or "1")
                    size_t slashPos = vertex.find('/');
                    std::string vertexIndex = (slashPos != std::string::npos) ? 
                                            vertex.substr(0, slashPos) : vertex;
                    int idx = std::stoi(vertexIndex) - 1; // OBJ indices are 1-based
                    face.vertices.push_back(idx);
                }
                mesh.faces.push_back(face);
            }
        }
        
        file.close();
        return true;
    }
};

class AlembicWriter {
private:
    Alembic::Abc::OArchive archive;
    OPolyMesh meshObj;
    OPolyMeshSchema meshSchema;
    double fps;
    
public:
    AlembicWriter(const std::string& filename, double fps = 24.0) : fps(fps) {
        // Create Alembic archive
        archive = Alembic::Abc::OArchive(Alembic::AbcCoreOgawa::WriteArchive(), filename);
        
        // Create top object
        Alembic::Abc::OObject topObj(archive, "ABC");
        
        // Create mesh object
        meshObj = OPolyMesh(topObj, "objSequenceMesh");
        meshSchema = meshObj.getSchema();
        
        // Set time sampling
        Alembic::Abc::TimeSampling ts(1.0/fps, 0.0);
        Alembic::Abc::uint32_t tsIndex = archive.addTimeSampling(ts);
        meshSchema.setTimeSampling(tsIndex);
    }
    
    bool writeMesh(const ObjMesh& mesh, size_t frameIndex) {
        try {
            // Convert vertices
            std::vector<Alembic::Abc::V3f> points;
            points.reserve(mesh.vertices.size());
            for (const auto& v : mesh.vertices) {
                points.emplace_back(v.x, v.y, v.z);
            }
            
            // Convert faces with reversed winding order to fix normals
            std::vector<Alembic::Abc::int32_t> faceIndices;
            std::vector<Alembic::Abc::int32_t> faceCounts;
            
            for (const auto& face : mesh.faces) {
                faceCounts.push_back(static_cast<Alembic::Abc::int32_t>(face.vertices.size()));
                
                // Reverse face vertex order to fix normal direction
                for (int i = static_cast<int>(face.vertices.size()) - 1; i >= 0; i--) {
                    faceIndices.push_back(face.vertices[i]);
                }
            }
            
            // Create array samples - ensure vectors are not empty
            if (points.empty() || faceIndices.empty() || faceCounts.empty()) {
                std::cerr << "Error: Empty geometry data in frame " << frameIndex << std::endl;
                return false;
            }
            
            // Create Alembic array samples with explicit namespace
            Alembic::Abc::P3fArraySample pointsSample(&points.front(), points.size());
            Alembic::Abc::Int32ArraySample faceIndicesSample(&faceIndices.front(), faceIndices.size());
            Alembic::Abc::Int32ArraySample faceCountsSample(&faceCounts.front(), faceCounts.size());
            
            // Create mesh sample with explicit namespace and direct assignment
            Alembic::AbcGeom::OPolyMeshSchema::Sample meshSample;
            meshSample.setPositions(pointsSample);
            meshSample.setFaceIndices(faceIndicesSample);
            meshSample.setFaceCounts(faceCountsSample);
            
            // Set the sample
            meshSchema.set(meshSample);
            
            std::cout << "Frame " << frameIndex << " written: " << points.size() 
                      << " vertices, " << mesh.faces.size() << " faces" << std::endl;
            
            return true;
        }
        catch (const std::exception& e) {
            std::cerr << "Error writing frame " << frameIndex << ": " << e.what() << std::endl;
            return false;
        }
    }
    
    ~AlembicWriter() {
        // Archive will be automatically closed
    }
};

bool extractFrameNumber(const std::string& filename, int& frameNumber) {
    // Try to extract frame number from filename using regex
    std::regex frameRegex(R"(.*?(\d+)\.obj$)", std::regex_constants::icase);
    std::smatch matches;
    
    if (std::regex_match(filename, matches, frameRegex)) {
        frameNumber = std::stoi(matches[1].str());
        return true;
    }
    
    return false;
}

std::vector<std::string> getObjFiles(const std::string& inputDir) {
    std::vector<std::string> objFiles;
    
    if (!fs::exists(inputDir) || !fs::is_directory(inputDir)) {
        std::cerr << "Error: Input directory does not exist: " << inputDir << std::endl;
        return objFiles;
    }
    
    for (const auto& entry : fs::directory_iterator(inputDir)) {
        if (entry.is_regular_file()) {
            std::string filename = entry.path().filename().string();
            std::string extension = entry.path().extension().string();
            std::transform(extension.begin(), extension.end(), extension.begin(), ::tolower);
            
            if (extension == ".obj") {
                objFiles.push_back(entry.path().string());
            }
        }
    }
    
    // Sort files by frame number
    std::sort(objFiles.begin(), objFiles.end(), [](const std::string& a, const std::string& b) {
        int frameA, frameB;
        std::string filenameA = fs::path(a).filename().string();
        std::string filenameB = fs::path(b).filename().string();
        
        bool hasFrameA = extractFrameNumber(filenameA, frameA);
        bool hasFrameB = extractFrameNumber(filenameB, frameB);
        
        if (hasFrameA && hasFrameB) {
            return frameA < frameB;
        }
        
        return filenameA < filenameB;
    });
    
    return objFiles;
}

void printUsage(const char* programName) {
    std::cout << "Usage: " << programName << " -input <input_directory> -output <output_file.abc> [-fps <fps_value>]" << std::endl;
    std::cout << "  -input   : Directory containing OBJ sequence files" << std::endl;
    std::cout << "  -output  : Output Alembic cache file path" << std::endl;
    std::cout << "  -fps     : Frames per second (default: 24)" << std::endl;
    std::cout << std::endl;
    std::cout << "Example:" << std::endl;
    std::cout << "  " << programName << " -input ./obj_sequence -output ./output.abc -fps 30" << std::endl;
}

int main(int argc, char* argv[]) {
    std::cout << "==================================================" << std::endl;
    std::cout << "OBJ Sequence to Alembic Cache Converter" << std::endl;
    std::cout << "Author: Jaewon Song (Dexter Studios R&D Director)" << std::endl;
    std::cout << "==================================================" << std::endl;
    
    std::string inputDir;
    std::string outputFile;
    double fps = 24.0;
    
    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        
        if (arg == "-input" && i + 1 < argc) {
            inputDir = argv[++i];
        }
        else if (arg == "-output" && i + 1 < argc) {
            outputFile = argv[++i];
        }
        else if (arg == "-fps" && i + 1 < argc) {
            fps = std::stod(argv[++i]);
        }
        else if (arg == "-h" || arg == "--help") {
            printUsage(argv[0]);
            return 0;
        }
    }
    
    // Validate arguments
    if (inputDir.empty() || outputFile.empty()) {
        std::cerr << "Error: Both -input and -output parameters are required." << std::endl;
        printUsage(argv[0]);
        return 1;
    }
    
    std::cout << "Input directory: " << inputDir << std::endl;
    std::cout << "Output file: " << outputFile << std::endl;
    std::cout << "FPS: " << fps << std::endl;
    std::cout << std::endl;
    
    // Get OBJ files
    std::vector<std::string> objFiles = getObjFiles(inputDir);
    
    if (objFiles.empty()) {
        std::cerr << "Error: No OBJ files found in directory: " << inputDir << std::endl;
        return 1;
    }
    
    std::cout << "Found " << objFiles.size() << " OBJ files:" << std::endl;
    for (size_t i = 0; i < objFiles.size(); i++) {
        std::cout << "  [" << i << "] " << fs::path(objFiles[i]).filename().string() << std::endl;
    }
    std::cout << std::endl;
    
    // Create Alembic writer
    try {
        AlembicWriter writer(outputFile, fps);
        
        auto startTime = std::chrono::high_resolution_clock::now();
        
        // Process each OBJ file
        for (size_t i = 0; i < objFiles.size(); i++) {
            std::cout << "Processing frame " << i << "/" << objFiles.size() << ": " 
                      << fs::path(objFiles[i]).filename().string() << "... ";
            
            ObjMesh mesh;
            if (ObjParser::parseObjFile(objFiles[i], mesh)) {
                if (writer.writeMesh(mesh, i)) {
                    std::cout << "OK" << std::endl;
                } else {
                    std::cout << "FAILED" << std::endl;
                    return 1;
                }
            } else {
                std::cout << "FAILED to parse" << std::endl;
                return 1;
            }
        }
        
        auto endTime = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime);
        
        std::cout << std::endl;
        std::cout << "==================================================" << std::endl;
        std::cout << "Conversion completed successfully!" << std::endl;
        std::cout << "Processed " << objFiles.size() << " frames in " 
                  << duration.count() << " ms" << std::endl;
        std::cout << "Output: " << outputFile << std::endl;
        std::cout << "==================================================" << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}