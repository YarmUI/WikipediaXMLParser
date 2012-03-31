#include <iostream>
#include <algorithm>
#include <fstream>
#include <vector>
#include <map>
#include <cstdint>
#include <string>
#include "Node.h"

const char* fin_pages  = "pages.txt";
const char* fin_links  = "links.txt";
const char* fon_pages  = "pages.bin";
const char* fon_links  = "links.bin";
const char* fon_titles = "titles.txt";

bool sort_first(std::pair<uint32_t, uint32_t> a, std::pair<uint32_t, uint32_t> b) {
  return a.first < b.first;
}

void drip(std::vector<Node>& nodes,
          std::vector<uint32_t>& links,
          std::vector<std::string>& titles ) {

  std::map<uint32_t, uint32_t> id2index;
  std::map<uint32_t, uint32_t> redirects;
  std::map<std::string, uint32_t> title2id;
  std::ifstream ifs_pages(fin_pages);
  for(uint32_t index = 0; ; ) {
    uint32_t id;
    bool redirect;
    std::string title;
    ifs_pages >> id >> title >> redirect;
    if(ifs_pages.eof()) break;
    title2id.insert(std::make_pair(title, id));
    if(redirect) {
      redirects.insert(std::make_pair(id, (uint32_t)0xFFFFFFFF));
    } else {
      nodes.push_back(Node());
      titles.push_back(title);
      id2index.insert(std::make_pair(id, index++));
    }
  }
  ifs_pages.close();

  std::ifstream ifs_links(fin_links);
  std::vector<std::pair<uint32_t, uint32_t>> redirect_links, tmp_links;
  while(true) {
    uint32_t from_id;
    std::string to_title;
    ifs_links >> from_id >> to_title;
    if(ifs_links.eof()) break;
    auto to_id_it = title2id.find(to_title);
    if(to_id_it == title2id.end()) continue;
    uint32_t to_id = to_id_it->second;
    auto from_it = redirects.find(from_id);
    auto to_it   = redirects.find(to_id);
    if(from_it != redirects.end()) {
      from_it->second = to_id;
    } else if(to_it != redirects.end()) {
      redirect_links.push_back(std::make_pair(from_id, to_id));
    } else {
      tmp_links.push_back(std::make_pair(from_id, to_id));
    }
  }
  ifs_links.close();

  for(uint32_t i = 0; i < redirect_links.size(); i++) {
    uint32_t from_id = redirect_links[i].first, to_id = redirect_links[i].second;
    auto to_it = redirects.find(to_id);
    if(to_it == redirects.end() || to_it->second == 0xFFFFFFFF) continue;
    to_id = to_it->second;
    if(redirects.find(to_id) != redirects.end()) {
      redirect_links.push_back(std::make_pair(from_id, to_id));
    } else {
      tmp_links.push_back(std::make_pair(from_id, to_id));
    }
  }

  for(auto it = tmp_links.begin(); it != tmp_links.end(); it++) {
    auto from_it = id2index.find(it->first);
    auto to_it   = id2index.find(it->second);
    if(from_it == id2index.end() || to_it == id2index.end()) {
      it->first  = 0xFFFFFFFF;
    } else {
      it->first  = from_it->second;
      it->second = to_it->second;
    }
  }
  std::sort(tmp_links.begin(), tmp_links.end(), sort_first);
  uint32_t index = tmp_links.begin()->first;
  for(auto it = tmp_links.begin(); it != tmp_links.end(); it++) {
    uint32_t from_index = it->first, to_index = it->second;
    if(from_index == 0xFFFFFFFF) break;
    links.push_back(to_index);
    if(index != from_index) {
      nodes[from_index].link_start = (nodes[index].link_end += nodes[index].link_start);
      index = from_index;
    }
    nodes[index].link_end++;
  }
  nodes[index].link_end += nodes[index].link_start;
}

int main(int argc, char const* argv[]) {
  std::vector<uint32_t> links;
  std::vector<Node> nodes;
  std::vector<std::string> titles;
  drip(nodes, links, titles);

  uint32_t size = nodes.size();
  std::ofstream ofs_nodes(fon_pages, std::ios::binary);
  ofs_nodes.write((char*) &size, sizeof(uint32_t));
  for(uint32_t i = 0; i < nodes.size(); i++)
    ofs_nodes.write((char*) &nodes[i], sizeof(Node));
  ofs_nodes.close();

  size = links.size();
  std::ofstream ofs_links(fon_links, std::ios::binary);
  ofs_links.write((char*) &size, sizeof(uint32_t));
  for(uint32_t i = 0; i < links.size(); i++)
    ofs_links.write((char*) &links[i], sizeof(uint32_t));
  ofs_links.close();

  std::ofstream ofs_titles(fon_titles);
  for(auto it = titles.begin(); it != titles.end(); it++)
    ofs_titles << *it << std::endl;
  return 0;
}
