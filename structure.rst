What is GNU Radio
=======================

The GNU Radio approach to signal processing
-------------------------------------------

GNU Radio is a framework to develop Signal Processing flowgraphs that enable users to build highly capable real-world systems that do audio processing, form mobile communication devices, track satellites, do radar and much more, all in computer software.

* Signal processing can take place in software, when you convert a recorded signal into a series of numbers. [picture microphone -> soundcard -> 010010, antenna->transceiver->01010] This can be audio, or it can be the reception of a mobile phone, a radar device, or any signal that has a well defined bandwidth and voltage range, depending on your analog to digital conversion device
*  The same takes place in reverse for example when you listen to music from an MP3 file on your PC or smartphone: A device converts a series of numbers back into an analog signal. These values, so called samples, were calculated from the file, processed in various ways and then transmitted to the digital-to-analog converter, your soundcard. [picture mp3 file -> mathematical function voodoo -> soundcard -> headphones)
* It's very helpful to imagine the flow of these values through different stages of their processing as a stream that goes through different signal processing blocks. These streams may split, and blocks might unite and combine them to produce a variable number of output streams.
* This brings us to the concept of Flowgraphs [picture GRC flowgraph]. GNU Radio Blocks form the Nodes of this graph, while the edges represent the directed signal flow between these. 
* GNU Radio is a framework to develop such blocks as well as building and controlling graphs of these:
    * you can combine existing blocks into a high-level flowgraph that does something as complex as receiving LTE modulated signals, and GNU Radio will automatically move the signal data between these and cause processing of the data when it is ready for processing
    * you can write your own blocks, that either combine existing blocks with some intelligence to provide new functionality together with some logic, or you can develop your own block that operates on the input data and outputs data.

Basically, as a GNU Radio user, you are able to develop complex signal processing applications by combining existing, well defined functionality or by just filling in the functionality you need, without having to worry about how to make everything work together. 

Thus, GNU Radio is mainly a framework for the development of signal processing blocks and their interaction. It comes with an extensive standard library of blocks, and there are a lot of systems available that a developer might build upon. However, GNU Radio itself is not a software that is ready to do something specific -- it's the user's job to build something useful out of it, though it already comes with a lot of useful working examples. Think of it as a set of building blocks.


A walk through the main architecture of GNU Radio
-------------------------------------------------

**Attention:** The technobabble starts here.

=========================

To guide you through the different entities that you need to know to get a headstart to GNU Radio, we'll move along an example:

[picture of example system. C'mon. Make something up]

Let's assume we want to build a system that can be used to receive a video from a remote communication partner and can in turn send video tothat partner.

Such a system of course contains some kind of physical reception and transmission device, which can be used to pick up the electromagnetic wwaves caught by an antenna, and to drive the antenna in order to transform electrical signals into airborne waves, bring it down from its carrier frequency and digitize it, and do the opposite for the transmission direction.

We need something to recognize the received signal, and set the timing right, so that the receiver knows when a symbol starts and when to expect more, and to fix frequency differences between sender and receiver.

Then the received signal [picture stem(noisy gaussian) or something -> 16 QAM conste. -> 0100] needs to converted to a stream of data symbols. These will then be processed by the video displaying software, so we need an interface to that. We choose to use a TCP socket sink for that.

In sending direction, we need basically all the same, but reverse (minus the synchronisation): An interface for data from an application, a constellation mapper, a pulse shaper, and then the interface to the hardware.

All these [picture highlight SDR part] can be done with GNU Radio. 

[Picture pseudo-flowgraph] Let's look at the flowgraph structure this implies:

* We have the *blocks* that make up the signal processing functionality of the flow graph.
  For ease of use, the synchronization block, which does frequency as well as timing correction, is a block that encapsulates other blocks.
  It is thus called a hierarchical or *hier block*. The constellation mapper and demapper always process one complex number to produce a integer, representing the data. Due to the 1:1 relationship between in- and output items it is a *sync block*;  if the ratio was fixed but not 1, it would be a *sync decimator* or *sync interpolator*, depending on whether the number of samples is de- or increased, respectively.
  If the relationship between in- and output is not fixed, then we have a *general block*, that informs GNU Radio each time anew how much in- and output it *consumed* or *produced*, respectively.
* Then there are the edges of the graph, or *connections*. These transport in- and output *items* from block to block.
  The type of the data determines the size of such items, and different blocks might have different numbers of in- and outputs. 
  The type and number of possible ports are being set by the blocks' *io signatures*.
* A block that (in respect to a flowgraph) only has outputs is called a *source*, a block having only inputs is a *sink*.
* *Items* can be samples, as between the hardware interface and the synchronisation block, they can be bytes, such as between the network sink / source and our flowgraph, and they can be vectors of such items of an arbitrary (but fixed) length.
  GNU Radio itself does not really care what's in these items, it just manages them as memory items, and therefore only needs to know their size and number.

So what happens now as soon as we have defined our flowgraph and tell GNU Radio to start running it?

1. Each of the non-hierarchical blocks are instances of subclasses of gr::block, having a *general_work* or *work* function (general blocks only have a general_work function, whilst sync blocks overloaded that to provide a more comfortable interface with fixed item ratios).

2. GNU Radio asks the source(s) to produce some output. As soon as there is some output, the scheduler calls the downstream block's (general) work function to process that.

3. If there is enough space in the buffers between the blocks, GNU Radio will automatically take care that as many blocks are executed parallely as possible. A source might already be producing samples while the downstream block is still processing the last chunk of work.

4. This goes on until the flow graph is stopped due to being either interrupted externally (a flow graph has a stop() method) or some block signals it's done. 

5. GNU Radio takes care to get the remaining buffer contents through the flowgraph and shuts it down.

