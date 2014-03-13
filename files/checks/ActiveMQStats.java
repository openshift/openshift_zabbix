/*
     Copyright 2012 Red Hat Inc.

     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.

   Purpose: Monitor JVM details for ActiveMQ

   Build Command:
        javac -Xlint:unchecked -cp $JAVA_HOME/lib/tools.jar ActiveMQStats.java

   Run:
        java -cp /path/to/ActiveMQStats.class ActiveMQStats
*/

import java.lang.management.*;
import java.io.*;
import java.util.*;
import javax.management.*;
import javax.management.remote.*;
import com.sun.tools.attach.*;

public class ActiveMQStats {

  public static void printHelp()
  {
      System.err.println(
        "Usage:  ActiveMQStats \n" +
        "This script attaches to the JVM and queries for information.\n\n" +
        "Examples:  activemq_stats mem\n" +
        "           activemq_stats threads");
  }

  public static void getThreadInfo(MBeanServerConnection mbsc) throws Exception
  {
      ObjectName objName = new ObjectName(ManagementFactory.THREAD_MXBEAN_NAME);
      Set<ObjectName> mbeans = mbsc.queryNames(objName, null);

      for (ObjectName name: mbeans) {
          ThreadMXBean threadBean;
          threadBean = ManagementFactory.newPlatformMXBeanProxy(
            mbsc, name.toString(), ThreadMXBean.class);
          long threadIds[] = threadBean.getAllThreadIds();

          for (long threadId: threadIds) {
            ThreadInfo threadInfo = threadBean.getThreadInfo(threadId);
            System.out.println (threadInfo.getThreadName() + " / " +
                threadInfo.getThreadState());
          }
      }
  }

  public static HashMap getMBeans(MBeanServerConnection mbsc, String bname) throws Exception
  {
        ObjectName queue = new ObjectName(bname);
        //int count = 0;
        Set<ObjectInstance> beans = mbsc.queryMBeans(queue, null);
        HashMap<Object, String> results = new HashMap<Object, String>();

        if (beans.size() == 1) {
            //count = 1;
            ObjectInstance inst = (ObjectInstance) beans.iterator().next();
            MBeanInfo binfo = mbsc.getMBeanInfo(inst.getObjectName());
            MBeanAttributeInfo[] attrs = binfo.getAttributes();
            //System.out.println("Attributes:");

            for (int i =0; i < attrs.length; ++i) {
                //System.out.println(" " + attrs[i].getName() +
                 //": " + attrs[i].getDescription() +
                   //(type=" + attrs[i].getType() + ")");
                //System.out.println("Value: " + mbsc.getAttribute(inst.getObjectName(), attrs[i].getName()));
                  results.put((Object)attrs[i].getName(), String.format("%s", mbsc.getAttribute(inst.getObjectName(), attrs[i].getName().toString())));
            }
        } else if (beans.size() > 1){
            Iterator it;
            for (it = beans.iterator(); it.hasNext();) {
                Object obj = it.next();
                if (obj instanceof ObjectInstance) {
                    results.put(obj, "0");
                    //count += 1;
                }
            }
        }
        return results;
  }

  public static void main(String args[]) throws Exception {

      String user = "activemq";
      String pass = "password";
      String host = "127.0.0.1";
      String port = "1099";
      String hostport = host + ":" + port;

      JMXServiceURL rmiurl = new JMXServiceURL("service:jmx:rmi://" + hostport + "/jndi/rmi://" + hostport + "/jmxrmi");

      Map<String, String[]> creds = new HashMap<String,String[]>(1);
      creds.put("jmx.remote.credentials", new String[] { user, pass } );

      JMXConnector connector = JMXConnectorFactory.connect(rmiurl, creds);
      MBeanServerConnection mbsc = connector.getMBeanServerConnection();
      MemoryMXBean remoteMemBean = ManagementFactory.newPlatformMXBeanProxy(
                        mbsc,
                        ManagementFactory.MEMORY_MXBEAN_NAME,
                        MemoryMXBean.class);
      ThreadMXBean remoteThreadBean = ManagementFactory.newPlatformMXBeanProxy(
                        mbsc,
                        ManagementFactory.THREAD_MXBEAN_NAME,
                        ThreadMXBean.class);

      /*   HEAP USAGE  */
      System.out.println("heap_used " + remoteMemBean.getHeapMemoryUsage().getUsed());
      System.out.println("heap_committed " + remoteMemBean.getHeapMemoryUsage().getCommitted());

      /*  NON-HEAP USAGE  */
      System.out.println("nonheap_used " + remoteMemBean.getNonHeapMemoryUsage().getUsed());
      System.out.println("nonheap_committed " + remoteMemBean.getNonHeapMemoryUsage().getCommitted());

      /*  THREAD COUNT */
      System.out.println("thread_count " + remoteThreadBean.getThreadCount());

      /*  QUEUE COUNT */
      String bname = "org.apache.activemq:type=Broker,brokerName=*,destinationType=Queue,destinationName=mcollective.reply*";
      System.out.println("queues " + getMBeans(mbsc, bname).size());

      /* MBean: mcollective-nodes */
      /* The Attributes:
        MemoryUsageByteCount, AverageEnqueueTime, MaxEnqueueTime,
        MinEnqueueTime, EnqueueCount, QueueSize, MemoryUsagePortion,
        InFlightCount, ExpiredCount, DispatchCount, DequeueCount
        ProducerCount, ConsumerCount, MemoryLimit, MaxProducersToAudit
        MaxAuditDepth, MaxPageSize */
      List<String> attrs = Arrays.asList(
        "MemoryUsageByteCount", "AverageEnqueueTime", "MaxEnqueueTime",
        "MinEnqueueTime", "EnqueueCount", "QueueSize", "MemoryUsagePortion",
        "InFlightCount", "ExpiredCount", "DispatchCount", "DequeueCount",
        "ProducerCount", "ConsumerCount", "MemoryLimit", "MaxProducersToAudit",
        "MaxAuditDepth", "MaxPageSize");

      bname = "org.apache.activemq:type=Broker,brokerName=*,destinationType=Queue,destinationName=mcollective.nodes";
      HashMap mBeanAttributesHash = getMBeans(mbsc, bname);

      Set resultsSet = mBeanAttributesHash.entrySet();
      Iterator it = resultsSet.iterator();
      while(it.hasNext()) {
         Map.Entry me = (Map.Entry) it.next();
         if (attrs.contains(me.getKey())) {
            System.out.println(String.format("%s %s", me.getKey(), me.getValue()));
         }
      }

      connector.close();
  }
}
