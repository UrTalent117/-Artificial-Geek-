package main

import (
	"bufio"
	"flag"
	"fmt"
	"net"
	"os"
	"os/signal"
	"strconv"
	"time"
)

// 服务器模式：监听端口并向客户端发送时间信息
func runServer(port int) {
	// 监听指定端口
	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		fmt.Fprintf(os.Stderr, "服务器启动失败: %v\n", err)
		os.Exit(1)
	}
	defer listener.Close()

	fmt.Printf("服务器已启动，正在监听端口 %d\n", port)
	fmt.Println("等待客户端连接...")

	// 接受客户端连接
	for {
		conn, err := listener.Accept()
		if err != nil {
			fmt.Fprintf(os.Stderr, "接受连接失败: %v\n", err)
			continue
		}

		fmt.Printf("客户端连接成功: %s\n", conn.RemoteAddr().String())

		// 为每个客户端创建一个goroutine处理连接
		go handleClient(conn)
	}
}

// 处理客户端连接，每秒发送一次时间信息
func handleClient(conn net.Conn) {
	defer func() {
		conn.Close()
		fmt.Printf("客户端断开连接: %s\n", conn.RemoteAddr().String())
	}()

	// 每秒向客户端发送一次时间信息
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			// 获取当前系统时间，格式为RFC3339标准格式
			timeStr := time.Now().Format(time.RFC3339)

			// 发送时间信息给客户端
			_, err := fmt.Fprintf(conn, "%s\n", timeStr)
			if err != nil {
				fmt.Fprintf(os.Stderr, "发送数据失败: %v\n", err)
				return
			}
		}
	}
}

// 客户端模式：连接到服务器并接收时间信息
func runClient(serverAddr string, port int) {
	// 连接到服务器
	conn, err := net.Dial("tcp", fmt.Sprintf("%s:%d", serverAddr, port))
	if err != nil {
		fmt.Fprintf(os.Stderr, "连接服务器失败: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close()

	fmt.Printf("已成功连接到服务器 %s:%d\n", serverAddr, port)
	fmt.Println("正在接收时间信息... (按Ctrl+C中断)")

	// 创建一个scanner来读取服务器发送的数据
	scanner := bufio.NewScanner(conn)

	// 设置信号处理，以便优雅地退出
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt)

	// 创建一个channel来接收scanner的结果
	resultChan := make(chan string)
	errChan := make(chan error)

	// 启动一个goroutine来读取数据
	go func() {
		for scanner.Scan() {
			resultChan <- scanner.Text()
		}
		if err := scanner.Err(); err != nil {
			errChan <- err
		} else {
			errChan <- nil
		}
	}()

	// 主循环：接收并显示时间信息
	for {
		select {
		case timeStr := <-resultChan:
			// 解析并显示时间信息
			fmt.Println(timeStr)
		case err := <-errChan:
			if err != nil {
				fmt.Fprintf(os.Stderr, "接收数据失败: %v\n", err)
			} else {
				fmt.Println("服务器已关闭连接")
			}
			return
		case <-sigChan:
			fmt.Println("\n正在中断连接...")
			return
		}
	}
}

func main() {
	// 解析命令行参数
	clientMode := flag.Bool("c", false, "客户端模式，连接到指定的服务器")
	flag.Parse()

	if *clientMode {
		// 客户端模式：需要两个参数：服务器地址和端口
		if len(flag.Args()) != 2 {
			fmt.Fprintln(os.Stderr, "用法: AG -c [IPv4地址] [端口]")
			os.Exit(1)
		}

		serverAddr := flag.Args()[0]
		port, err := strconv.Atoi(flag.Args()[1])
		if err != nil || port <= 0 || port > 65535 {
			fmt.Fprintln(os.Stderr, "错误: 端口号必须是1-65535之间的整数")
			os.Exit(1)
		}

		runClient(serverAddr, port)
	} else {
		// 服务器模式：可选参数：端口（默认8080）
		port := 8080
		if len(flag.Args()) == 1 {
			p, err := strconv.Atoi(flag.Args()[0])
			if err != nil || p <= 0 || p > 65535 {
				fmt.Fprintln(os.Stderr, "错误: 端口号必须是1-65535之间的整数")
				os.Exit(1)
			}
			port = p
		} else if len(flag.Args()) > 1 {
			fmt.Fprintln(os.Stderr, "用法: AG [端口] 或 AG -c [IPv4地址] [端口]")
			os.Exit(1)
		}

		runServer(port)
	}
}
