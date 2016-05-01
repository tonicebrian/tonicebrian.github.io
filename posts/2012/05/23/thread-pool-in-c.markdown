---
comments: true
date: 2012-05-23 17:30:07
layout: post
slug: thread-pool-in-c
title: Thread pool in C++
wordpressid: 381
categories: Programming
tags: boost,c++,multithreading
---

![](BoostLogo.png)

I needed to convert user ids spread across a lot of files into a fixed range [0..N] where N was the total number of Ids in the dataset. First I though that since those files came from a Hadoop cluster I should write a MR job to do the task. But since recoding ids needs a "central authority" giving unique ids without collision, MapReduce wasn't an option because MR thinks about each record as independent of the rest of records, so coordinating the assignment of ids is both difficult and unnatural in MapReduce. The naïve approach is to create a counter, loop through all the ids and whenever an id is not in the dictionary, use the counter as the new translation. See the pseudocode

``` python
int counter = 0;
for id in ids:
    if id not in dict:
        dict[id] = counter
        counter++
    print dict[i]
```
But then you are wasting precious cores that could help you. My machine has eight cores, so for a task that runs in aprox 60 minutes, so after investing time in going beyond the naïve approach, I'm able to lower it to 10 minutes. That means that I can run tests 6 times faster, it will pay off.

### Lookup table

So the first thing to do is to create a thread safe Hash Map. Most of the time the access will be for reading a value and less frequently for updating the data structure (in my problem I perform 250 reads for each write) so this scenario is ideal for a [Readers-writer lock](http://en.wikipedia.org/wiki/Readers%E2%80%93writer_lock). I use the Boost Thread library with its boost::shared_mutex for getting the multiple access functionality. The class is something like this

``` cpp
using namespace boost;
class LookupTable {
    private:
        typedef std::unordered_map<int,unsigned int> HashMap;
        HashMap dict;
        unsigned int counter;
        shared_mutex m_mutex; 
    public:
        LookupTable(){};
        unsigned int translate(int number){
            boost::shared_lock<boost::shared_mutex> lck(m_mutex);
            unsigned int result;
            HashMap::iterator elem = dict.find(key);
            if( elem == dict.end()){
               lck.unlock();
               boost::upgrade_lock<boost::shared_mutex> uLck(m_mutex);
               boost::upgrade_to_unique_lock<boost::shared_mutex> uuLck(uLck);
               dict[key] = counter;
               result = counter;
               counter++;
            } else {
               result = elem->second;
            }
            return result;
        }
};
```

### Thread pool

Once we have the thread safe data structure in place, we want to create a thread pool were we can send tasks. The thread pool will be responsible to assign each task to the next free thread. The reason for having a thread pool instead of spawning as many threads as tasks is two fold, first, the amount of work I can do is bounded by the speed at which I'm able to read from disk, so throwing more threads doesn't seem to help here. Second, since all the threads must query the lookup table, if there are lots of them the synchronization (mutex locking and unlocking) could become heavier than the work per thread becoming a bottleneck.

Boost provides a nice thread pool by using the Boost::Asio library. I came to this pattern of usage by reading [this](http://mostlycoding.blogspot.com.es/2009/05/asio-library-has-been-immensely-helpful.html) and [this](http://think-async.com/Asio/Recipes) but it happens that they are wrong in a subtle detail. As they are written, they only run one task per thread and then the io_service is stopped. After scratching my head for a couple of hours I reread the official documentation and the solution is explained [at them botom of the page](http://www.boost.org/doc/libs/1_49_0/doc/html/boost_asio/reference/io_service.html). So the key issue is to destroy explicitly the work variable that we created for the io_service to not end too early. To accomplish that just embed the work in a smart pointer std::auto_ptr and reset it when necessary, the reset will call the work destructor.

So the main program would be something like this

``` cpp
// Thread pool
asio::io_service io_service;
boost::thread_group threads;
auto_ptr<asio::io_service::work> work(new asio::io_service::work(io_service)); 

// Spawn enough worker threads
int cores_number = boost::thread::hardware_concurrency(); 
for (std::size_t i = 0; i < cores_number; ++i){
    threads.create_thread(boost::bind(&asio::io_service::run, &io_service));
}
// Post the tasks to the io_service
for(vector<string>::iterator it=filenames.begin();it!=filenames.end();it++){
   io_service.dispatch(std::move(translator(*it,dict)));
}
work.reset();
```

and the code for the worker (sketched)

``` cpp
struct translator {
    translator(string filename, LookupTable& dict)
        : m_filename(filename),m_dict(dict)
    {
    }
    void operator()(){
        // DO YOUR WORKER ACTIVITY HERE
        ...
        return;
    }
}
```
